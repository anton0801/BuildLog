import SwiftUI
import WebKit

enum AppTab: Int, CaseIterable {
    case dashboard = 0
    case projects = 1
    case tasks = 2
    case timeline = 3
    case settings = 4

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .projects: return "Projects"
        case .tasks: return "Tasks"
        case .timeline: return "Timeline"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .projects: return "folder"
        case .tasks: return "checkmark.circle"
        case .timeline: return "clock"
        case .settings: return "gearshape"
        }
    }

    var activeIcon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .projects: return "folder.fill"
        case .tasks: return "checkmark.circle.fill"
        case .timeline: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var selectedTab: AppTab = .dashboard
    @State private var tabAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Content
            ZStack {
                switch selectedTab {
                case .dashboard:
                    NavigationView {
                        DashboardView()
                    }
                    .transition(.opacity)
                case .projects:
                    NavigationView {
                        ProjectsView()
                    }
                    .transition(.opacity)
                case .tasks:
                    NavigationView {
                        TasksView()
                    }
                    .transition(.opacity)
                case .timeline:
                    NavigationView {
                        TimelineView()
                    }
                    .transition(.opacity)
                case .settings:
                    NavigationView {
                        SettingsView()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @State private var pressedTab: AppTab? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                CustomTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isPressed: pressedTab == tab
                ) {
                    if selectedTab != tab {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, safeAreaBottom)
        .background(
            ZStack {
                Color(.systemBackground)
                Rectangle()
                    .fill(AppColors.separator)
                    .frame(height: 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
    }

    private var safeAreaBottom: CGFloat {
        let window = UIApplication.shared.windows.first
        return (window?.safeAreaInsets.bottom ?? 0) > 0 ? (window?.safeAreaInsets.bottom ?? 0) : 16
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}


struct CustomTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let isPressed: Bool
    let action: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bouncing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                bouncing = false
            }
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.secondaryText)
                    .scaleEffect(bouncing ? 1.3 : (isSelected ? 1.1 : 1.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: bouncing)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.secondaryText)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
