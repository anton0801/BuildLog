import SwiftUI

@main
struct BuildLogApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
                .preferredColorScheme(settingsViewModel.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0

    var body: some View {
        ZStack {
            mainContent
                .transition(.opacity)
        }
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

struct BuildLogConfig {
    static let appID = "6760728329"
    static let devKey = "3NAmXPMJnVwdHjUmTyYhAH"
}
