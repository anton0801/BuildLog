import SwiftUI

@main
struct BuildLogApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
                .preferredColorScheme(settingsViewModel.colorScheme)
        }
    }
}

// MARK: - Root View (handles splash, onboarding, auth, main flow)
struct RootView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0

    var body: some View {
        ZStack {
            if showSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.4)) {
                        splashOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showSplash = false
                    }
                }
                .opacity(splashOpacity)
                .zIndex(1)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
    }

    @ViewBuilder
    private var mainContent: some View {
        if !settingsViewModel.hasCompletedOnboarding {
            OnboardingView {
                // Onboarding complete
            }
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        } else if !appViewModel.isAuthenticated {
            AuthView()
                .environmentObject(appViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        } else {
            MainTabView()
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }
}
