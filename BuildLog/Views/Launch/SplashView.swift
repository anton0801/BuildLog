import SwiftUI

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var iconRotation: Double = -30
    @State private var backgroundOpacity: Double = 0
    
    @StateObject private var viewModel: BuildLogViewModel
    
    init() {
        let trackingRepo = UserDefaultsTrackingRepository()
        let navigationRepo = UserDefaultsNavigationRepository()
        let configRepo = UserDefaultsConfigurationRepository()
        let permissionRepo = UserDefaultsPermissionRepository()
        let validationService = FirebaseValidationServiceImpl()
        let attributionService = AppsFlyerAttributionServiceImpl()
        let endpointService = HTTPEndpointServiceImpl()
        let notificationService = SystemNotificationServiceImpl()
        
        var viewModel: BuildLogViewModel!
        
        let application = BuildLogApplication(
            trackingRepo: trackingRepo,
            navigationRepo: navigationRepo,
            configRepo: configRepo,
            permissionRepo: permissionRepo,
            validationService: validationService,
            attributionService: attributionService,
            endpointService: endpointService,
            notificationService: notificationService,
            eventHandler: { event in
                Task { @MainActor in
                    viewModel?.handleEvent(event)
                }
            }
        )
        
        viewModel = BuildLogViewModel(application: application)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#1a5fb4"),
                        Color(hex: "#2F80ED"),
                        Color(hex: "#4a9af0")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image("build_log_load_scr")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea().opacity(0.6)
                        .blur(radius: 3)
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Animated Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 90, height: 90)
                        
                        ZStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(.white)
                                .offset(y: -4)
                            
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Color(hex: "#FF8A00"))
                                .offset(x: 18, y: 14)
                                .rotationEffect(.degrees(45))
                        }
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .rotationEffect(.degrees(iconRotation))
                    
                    Spacer().frame(height: 36)
                    
                    // App Name
                    VStack(spacing: 8) {
                        Text("Build Log")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(titleOpacity)
                        
                        Text("Wait when loads data...")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                            .opacity(subtitleOpacity)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        ProgressView().tint(.white)
                    }
                    
                    Spacer()
                    
                    // Bottom tagline
                    VStack(spacing: 4) {
                        Text("Build Log")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                        Text("v2.10.0")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 40)
                }
                
                NavigationLink(
                    destination: BuildLogWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
            }
            .onAppear {
                startAnimations()
                viewModel.start()
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                BuildLogNotificationView(
                    onAllow: { viewModel.requestPermission() },
                    onDefer: { viewModel.deferPermission() }
                )
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func startAnimations() {
        // Stage 1: Background fade in
        withAnimation(.easeIn(duration: 0.3)) {
            backgroundOpacity = 1
        }

        // Stage 2: Icon appears with spring
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconRotation = 0
        }

        // Stage 3: Title fades in
        withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
            titleOpacity = 1.0
        }

        // Stage 4: Subtitle fades in
        withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
            subtitleOpacity = 1.0
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}

struct BuildLogNotificationView: View {
    let onAllow: () -> Void
    let onDefer: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "build_log_push_scr_bg_ld" : "build_log_push_scr_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("LondrinaSolid-Black", size: 24))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("LondrinaSolid-Regular", size: 16))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { onAllow() } label: {
                Image("build_log_push_scr_btn1")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button { onDefer() } label: {
                Image("build_log_push_scr_btn2")
                    .resizable()
                    .frame(width: 260, height: 30)
            }
        }
        .padding(.horizontal, 12)
    }
}


struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "build_log_inet_scr_ld" : "build_log_inet_scr")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9).blur(radius: 2)
                
                Image("build_log_inet_scr_alert")
                    .resizable()
                    .frame(width: 250, height: 180)
            }
        }
        .ignoresSafeArea()
    }
}
