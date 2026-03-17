import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var animateCharts = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Stats
                ReportSummaryCard(appViewModel: appViewModel, currency: settingsViewModel.currency)
                    .padding(.horizontal, 20)

                // Budget Distribution (Donut Chart)
                if !appViewModel.expenses.isEmpty {
                    BudgetDonutChart(
                        expenses: appViewModel.expenses,
                        currency: settingsViewModel.currency,
                        animate: $animateCharts
                    )
                    .padding(.horizontal, 20)
                }

                // Room Progress (Horizontal Bars)
                if !appViewModel.projects.isEmpty {
                    RoomProgressChart(
                        projects: appViewModel.projects,
                        animate: $animateCharts
                    )
                    .padding(.horizontal, 20)
                }

                // Task Completion Donut
                if !appViewModel.allTasks.isEmpty {
                    TaskCompletionDonut(
                        tasks: appViewModel.allTasks,
                        animate: $animateCharts
                    )
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 16)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateCharts = true
            }
        }
        .onDisappear {
            animateCharts = false
        }
    }
}

// MARK: - Report Summary Card
struct ReportSummaryCard: View {
    let appViewModel: AppViewModel
    let currency: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Project Overview")
                .font(AppFonts.title3())
                .foregroundColor(AppColors.labelColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ReportStatCell(
                    title: "Projects",
                    value: "\(appViewModel.projects.count)",
                    icon: "folder.fill",
                    color: AppColors.primary
                )
                ReportStatCell(
                    title: "Tasks",
                    value: "\(appViewModel.allTasks.count)",
                    icon: "checkmark.circle.fill",
                    color: AppColors.progress
                )
                ReportStatCell(
                    title: "Total Spent",
                    value: appViewModel.totalSpent.currencyString(currency: currency),
                    icon: "dollarsign.circle.fill",
                    color: AppColors.accent
                )
                ReportStatCell(
                    title: "Contractors",
                    value: "\(appViewModel.contractors.count)",
                    icon: "person.2.fill",
                    color: Color(hex: "#9B51E0")
                )
            }
        }
        .cardStyle()
    }
}

struct ReportStatCell: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Budget Donut Chart
struct BudgetDonutChart: View {
    let expenses: [Expense]
    let currency: String
    @Binding var animate: Bool

    var categoryTotals: [(category: ExpenseCategory, amount: Double, percentage: Double)] {
        var totals: [ExpenseCategory: Double] = [:]
        for exp in expenses {
            totals[exp.category, default: 0] += exp.amount
        }
        let total = totals.values.reduce(0, +)
        return totals.map { (
            category: $0.key,
            amount: $0.value,
            percentage: total > 0 ? $0.value / total : 0
        )}
        .sorted { $0.amount > $1.amount }
    }

    var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Distribution")
                .font(AppFonts.title3())
                .foregroundColor(AppColors.labelColor)

            HStack(spacing: 20) {
                // Donut Chart
                ZStack {
                    DonutChartShape(
                        segments: categoryTotals.map { DonutSegment(value: $0.amount, color: $0.category.color) },
                        animate: animate
                    )
                    .frame(width: 140, height: 140)

                    VStack(spacing: 2) {
                        Text("Total")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.secondaryText)
                        Text(total.currencyString(currency: currency))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.labelColor)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categoryTotals.prefix(5), id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 10, height: 10)
                            Text(item.category.rawValue)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(item.percentage * 100))%")
                                .font(AppFonts.caption())
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.labelColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
}

// MARK: - Donut Chart Segment
struct DonutSegment {
    let value: Double
    let color: Color
}

struct DonutChartShape: View {
    let segments: [DonutSegment]
    let animate: Bool

    var total: Double {
        segments.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                DonutSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: segment.color,
                    animate: animate
                )
            }
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: 90, height: 90)
        }
    }

    private func startAngle(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        let previousTotal = segments.prefix(index).reduce(0) { $0 + $1.value }
        return (previousTotal / total) * 360 - 90
    }

    private func endAngle(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        let currentTotal = segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return (currentTotal / total) * 360 - 90
    }
}

struct DonutSlice: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let animate: Bool

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) / 2
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(animate ? endAngle : startAngle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
    }
}

// MARK: - Room Progress Chart
struct RoomProgressChart: View {
    let projects: [Project]
    @Binding var animate: Bool

    var roomData: [(name: String, progress: Double, taskCount: Int)] {
        projects.flatMap { project in
            project.rooms.map { room in
                (name: "\(room.name)", progress: room.progress, taskCount: room.tasks.count)
            }
        }
        .prefix(8)
        .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Room Progress")
                .font(AppFonts.title3())
                .foregroundColor(AppColors.labelColor)

            if roomData.isEmpty {
                Text("No rooms to display")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.secondaryText)
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(roomData.enumerated()), id: \.offset) { index, room in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(room.name)
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.labelColor)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(room.progress * 100))%")
                                    .font(AppFonts.caption())
                                    .fontWeight(.semibold)
                                    .foregroundColor(room.progress >= 1.0 ? AppColors.progress : AppColors.primary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 10)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(room.progress >= 1.0 ? AppColors.progress : AppColors.primary)
                                        .frame(
                                            width: animate ? geo.size.width * CGFloat(room.progress) : 0,
                                            height: 10
                                        )
                                        .animation(
                                            .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05),
                                            value: animate
                                        )
                                }
                            }
                            .frame(height: 10)
                            Text("\(room.taskCount) tasks")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Task Completion Donut
struct TaskCompletionDonut: View {
    let tasks: [TaskItem]
    @Binding var animate: Bool

    var todoCount: Int { tasks.filter { $0.status == .todo }.count }
    var inProgressCount: Int { tasks.filter { $0.status == .inProgress }.count }
    var doneCount: Int { tasks.filter { $0.status == .done }.count }
    var total: Int { tasks.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Completion")
                .font(AppFonts.title3())
                .foregroundColor(AppColors.labelColor)

            HStack(spacing: 24) {
                // Donut
                ZStack {
                    DonutChartShape(
                        segments: [
                            DonutSegment(value: Double(doneCount), color: AppColors.progress),
                            DonutSegment(value: Double(inProgressCount), color: AppColors.accent),
                            DonutSegment(value: Double(todoCount), color: AppColors.primary)
                        ],
                        animate: animate
                    )
                    .frame(width: 120, height: 120)

                    VStack(spacing: 2) {
                        Text("\(total)")
                            .font(AppFonts.title2())
                            .foregroundColor(AppColors.labelColor)
                        Text("tasks")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }

                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    TaskStatRow(
                        label: "Done",
                        count: doneCount,
                        total: total,
                        color: AppColors.progress
                    )
                    TaskStatRow(
                        label: "In Progress",
                        count: inProgressCount,
                        total: total,
                        color: AppColors.accent
                    )
                    TaskStatRow(
                        label: "To Do",
                        count: todoCount,
                        total: total,
                        color: AppColors.primary
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
}

struct TaskStatRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(Double(count) / Double(total) * 100)
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
            Spacer()
            Text("\(count) (\(percentage)%)")
                .font(AppFonts.caption())
                .fontWeight(.semibold)
                .foregroundColor(AppColors.labelColor)
        }
    }
}
