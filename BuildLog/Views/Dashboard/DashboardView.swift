import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showAddTask = false
    @State private var showAddExpense = false
    @State private var showAddMaterial = false
    @State private var showAddPhoto = false
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(appViewModel.currentUser?.name.components(separatedBy: " ").first ?? "there")!")
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.labelColor)
                        Text(Date().mediumDate)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Text(String(appViewModel.currentUser?.name.prefix(1) ?? "U"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Active Project Card
                if let project = appViewModel.activeProject {
                    ActiveProjectCard(project: project)
                        .padding(.horizontal, 20)
                } else if !appViewModel.projects.isEmpty {
                    ActiveProjectCard(project: appViewModel.projects[0])
                        .padding(.horizontal, 20)
                } else {
                    NoActiveProjectCard()
                        .padding(.horizontal, 20)
                }

                // Budget Status
                BudgetStatusCard()
                    .padding(.horizontal, 20)

                // Today's Tasks
                VStack(spacing: 12) {
                    SectionHeader(title: "Today's Tasks")
                        .padding(.horizontal, 20)

                    if appViewModel.todaysTasks.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.progress)
                            Text("No tasks due today")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.secondaryText)
                            Spacer()
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    } else {
                        ForEach(appViewModel.todaysTasks.prefix(3)) { task in
                            DashboardTaskRow(task: task)
                                .padding(.horizontal, 20)
                        }
                    }
                }

                // Recent Photos
                if !appViewModel.recentPhotos.isEmpty {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Recent Photos")
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(appViewModel.recentPhotos.prefix(6)) { photo in
                                    RecentPhotoThumbnail(photo: photo)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                // Quick Actions
                VStack(spacing: 12) {
                    SectionHeader(title: "Quick Actions")
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        QuickActionButton(
                            title: "Add Task",
                            icon: "plus.circle.fill",
                            color: AppColors.primary
                        ) {
                            showAddTask = true
                        }
                        QuickActionButton(
                            title: "Add Photo",
                            icon: "camera.fill",
                            color: AppColors.progress
                        ) {
                            showAddPhoto = true
                        }
                        QuickActionButton(
                            title: "Add Expense",
                            icon: "dollarsign.circle.fill",
                            color: AppColors.accent
                        ) {
                            showAddExpense = true
                        }
                        QuickActionButton(
                            title: "Add Material",
                            icon: "shippingbox.fill",
                            color: Color(hex: "#9B51E0")
                        ) {
                            showAddMaterial = true
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 4)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showAddTask) {
            CreateTaskView(isPresented: $showAddTask)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(isPresented: $showAddExpense)
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $showAddMaterial) {
            AddMaterialView(isPresented: $showAddMaterial)
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $showAddPhoto) {
            AddPhotoView(isPresented: $showAddPhoto)
                .environmentObject(appViewModel)
        }
    }

    @MainActor
    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 800_000_000)
        appViewModel.objectWillChange.send()
    }
}

// MARK: - Active Project Card
struct ActiveProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Project")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                    Text(project.name)
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.labelColor)
                }
                Spacer()
                ProgressRing(progress: project.progress, lineWidth: 6, size: 52)
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(project.rooms.count) rooms")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                    Spacer()
                    Text("\(project.totalTaskCount) tasks")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.progress)
                            .frame(width: geo.size.width * CGFloat(project.progress), height: 6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: project.progress)
                    }
                }
                .frame(height: 6)
            }

            // Status badge
            BadgeView(text: project.status.rawValue, color: Color(hex: project.status.color))
        }
        .cardStyle()
    }
}

// MARK: - No Active Project Card
struct NoActiveProjectCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text("No Active Project")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                Text("Create a project to get started")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.secondaryText)
        }
        .cardStyle()
    }
}

// MARK: - Budget Status Card
struct BudgetStatusCard: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Budget Status")

            HStack(spacing: 0) {
                BudgetStatItem(
                    title: "Total Budget",
                    amount: appViewModel.totalBudget,
                    color: AppColors.primary,
                    currency: settingsViewModel.currency
                )
                Divider()
                BudgetStatItem(
                    title: "Spent",
                    amount: appViewModel.totalSpent,
                    color: AppColors.accent,
                    currency: settingsViewModel.currency
                )
                Divider()
                BudgetStatItem(
                    title: "Remaining",
                    amount: max(appViewModel.budgetRemaining, 0),
                    color: AppColors.progress,
                    currency: settingsViewModel.currency
                )
            }
            .frame(height: 60)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(appViewModel.budgetProgress > 0.9 ? AppColors.warning : AppColors.accent)
                        .frame(width: geo.size.width * CGFloat(appViewModel.budgetProgress), height: 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appViewModel.budgetProgress)
                }
            }
            .frame(height: 10)

            Text("\(Int(appViewModel.budgetProgress * 100))% of budget used")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
        }
        .cardStyle()
    }
}

struct BudgetStatItem: View {
    let title: String
    let amount: Double
    let color: Color
    let currency: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
            Text(amount.currencyString(currency: currency))
                .font(AppFonts.headline())
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Dashboard Task Row
struct DashboardTaskRow: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let task: TaskItem

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                appViewModel.advanceTaskStatus(task)
            }) {
                Image(systemName: task.status.icon)
                    .font(.system(size: 20))
                    .foregroundColor(task.status.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.labelColor)
                    .strikethrough(task.status == .done)
                if let deadline = task.deadline {
                    Text(deadline.relativeDateString)
                        .font(AppFonts.caption())
                        .foregroundColor(task.isOverdue ? AppColors.warning : AppColors.secondaryText)
                }
            }

            Spacer()

            BadgeView(text: task.priority.rawValue, color: task.priority.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Recent Photo Thumbnail
struct RecentPhotoThumbnail: View {
    let photo: Photo

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = loadImage(from: photo.imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.secondaryText)
                    )
            }
        }
        .cornerRadius(12)
    }

    private func loadImage(from path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(title)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.labelColor)
                Spacer()
            }
            .padding(14)
            .background(AppColors.cardBackground)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
    }
}
