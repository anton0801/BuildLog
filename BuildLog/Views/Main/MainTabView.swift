import SwiftUI

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
        ZStack(alignment: .bottom) {
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

// MARK: - Custom Tab Item
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
