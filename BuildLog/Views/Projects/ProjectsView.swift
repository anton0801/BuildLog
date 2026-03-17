import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showCreateProject = false
    @State private var projectToDelete: Project? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if appViewModel.projects.isEmpty {
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "No Projects Yet",
                        subtitle: "Create your first renovation project to get started.",
                        buttonTitle: "Create Project",
                        buttonAction: { showCreateProject = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(appViewModel.projects) { project in
                                NavigationLink(destination:
                                    ProjectDetailView(project: project)
                                        .environmentObject(appViewModel)
                                        .environmentObject(settingsViewModel)
                                ) {
                                    ProjectCard(project: project, currency: settingsViewModel.currency)
                                        .padding(.horizontal, 20)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        projectToDelete = project
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete Project", systemImage: "trash")
                                    }
                                }
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .background(AppColors.background.ignoresSafeArea())

            // FAB
            FABButton(action: { showCreateProject = true })
                .padding(.trailing, 24)
                .padding(.bottom, 100)
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateProject) {
            CreateProjectView(isPresented: $showCreateProject)
                .environmentObject(appViewModel)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Project"),
                message: Text("Are you sure you want to delete \"\(projectToDelete?.name ?? "")\"? This will also delete all rooms, tasks, and expenses associated with this project."),
                primaryButton: .destructive(Text("Delete")) {
                    if let project = projectToDelete {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            appViewModel.deleteProject(project)
                        }
                        projectToDelete = nil
                    }
                },
                secondaryButton: .cancel {
                    projectToDelete = nil
                }
            )
        }
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    let project: Project
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: project.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(project.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.labelColor)
                        .lineLimit(1)
                    Text(project.type.rawValue)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()

                BadgeView(text: project.status.rawValue, color: Color(hex: project.status.color))
            }

            // Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                    Spacer()
                    Text("\(Int(project.progress * 100))%")
                        .font(AppFonts.caption())
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.progress)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.progress)
                            .frame(width: geo.size.width * CGFloat(project.progress), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Stats Row
            HStack {
                ProjectStatChip(icon: "square.split.2x2", value: "\(project.rooms.count)", label: "Rooms")
                Spacer()
                ProjectStatChip(icon: "checkmark.circle", value: "\(project.totalTaskCount)", label: "Tasks")
                Spacer()
                ProjectStatChip(icon: "banknote", value: project.budget.currencyString(currency: currency), label: "Budget")
            }

            // Start date
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
                Text("Started \(project.startDate.shortDate)")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .cardStyle()
    }
}

struct ProjectStatChip: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
                Text(value)
                    .font(AppFonts.caption())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.labelColor)
                    .lineLimit(1)
            }
            Text(label)
                .font(AppFonts.caption2())
                .foregroundColor(AppColors.secondaryText)
        }
    }
}
