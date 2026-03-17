import SwiftUI

struct TasksView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedFilter: TaskStatus? = nil
    @State private var showCreateTask = false
    @State private var taskToDelete: TaskItem? = nil
    @State private var showDeleteAlert = false

    var filteredTasks: [TaskItem] {
        let all = appViewModel.allTasks
        if let filter = selectedFilter {
            return all.filter { $0.status == filter }
        }
        return all
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All (\(appViewModel.allTasks.count))", isSelected: selectedFilter == nil) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = nil
                            }
                        }
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            let count = appViewModel.allTasks.filter { $0.status == status }.count
                            FilterChip(title: "\(status.rawValue) (\(count))", isSelected: selectedFilter == status) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = selectedFilter == status ? nil : status
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                if filteredTasks.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: selectedFilter == nil ? "No Tasks" : "No \(selectedFilter!.rawValue) Tasks",
                        subtitle: "Create a task to start tracking your renovation work.",
                        buttonTitle: "Add Task",
                        buttonAction: { showCreateTask = true }
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskCard(task: task)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            appViewModel.advanceTaskStatus(task)
                                        }
                                    } label: {
                                        Label("Next Status", systemImage: task.status.next.icon)
                                    }
                                    .tint(task.status.next.color)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        taskToDelete = task
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(AppColors.background)
                }
            }
            .background(AppColors.background.ignoresSafeArea())

            FABButton(action: { showCreateTask = true })
                .padding(.trailing, 24)
                .padding(.bottom, 100)
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateTask) {
            CreateTaskView(isPresented: $showCreateTask)
                .environmentObject(appViewModel)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Task"),
                message: Text("Are you sure you want to delete \"\(taskToDelete?.title ?? "")\"?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let task = taskToDelete {
                        appViewModel.deleteTask(task)
                        taskToDelete = nil
                    }
                },
                secondaryButton: .cancel {
                    taskToDelete = nil
                }
            )
        }
    }
}

// MARK: - Task Card
struct TaskCard: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        appViewModel.advanceTaskStatus(task)
                    }
                }) {
                    Image(systemName: task.status.icon)
                        .font(.system(size: 22))
                        .foregroundColor(task.status.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.labelColor)
                        .strikethrough(task.status == .done)
                        .lineLimit(2)
                    Text(appViewModel.roomName(for: task.roomID))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
                BadgeView(text: task.priority.rawValue, color: task.priority.color)
            }

            if !task.description.isEmpty {
                Text(task.description)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }

            // Footer
            HStack(spacing: 12) {
                if let deadline = task.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(deadline.relativeDateString)
                            .font(AppFonts.caption())
                    }
                    .foregroundColor(task.isOverdue ? AppColors.warning : AppColors.secondaryText)
                }

                if task.estimatedCost > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 11))
                        Text(task.estimatedCost.currencyString())
                            .font(AppFonts.caption())
                    }
                    .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                BadgeView(text: task.status.rawValue, color: task.status.color)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
