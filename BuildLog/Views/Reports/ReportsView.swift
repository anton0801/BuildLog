import SwiftUI
import Charts

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    enum TimeFilter: String, CaseIterable {
        case allTime      = "All time"
        case thisMonth    = "This month"
        case last3Months  = "Last 3 months"
        case custom       = "Custom"
    }

    @State private var selectedFilter: TimeFilter = .allTime
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var customEnd   = Date()
    @State private var showCustomPicker = false
    @State private var animateCharts = false
    @State private var showExport = false
    @State private var exportImage: UIImage? = nil

    var filteredExpenses: [Expense] {
        let now = Date()
        let cal = Calendar.current
        switch selectedFilter {
        case .allTime:      return appViewModel.expenses
        case .thisMonth:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            return appViewModel.expenses.filter { $0.date >= start }
        case .last3Months:
            let start = cal.date(byAdding: .month, value: -3, to: now) ?? now
            return appViewModel.expenses.filter { $0.date >= start }
        case .custom:
            return appViewModel.expenses.filter { $0.date >= customStart && $0.date <= customEnd }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sticky-ish filter bar
                filterBar
                    .padding(.horizontal, 20)

                // Custom date range picker
                if selectedFilter == .custom && showCustomPicker {
                    customDateCard
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Chart 0: Summary stats
                ReportSummaryCard(appViewModel: appViewModel, currency: settingsViewModel.currency)
                    .padding(.horizontal, 20)

                // Chart 1: Budget donut
                if !filteredExpenses.isEmpty {
                    BudgetDonutChart(
                        expenses: filteredExpenses,
                        totalBudget: appViewModel.totalBudget,
                        currency: settingsViewModel.currency,
                        animate: $animateCharts
                    )
                    .padding(.horizontal, 20)
                }

                // Chart 2: Budget burn line
                if filteredExpenses.count >= 2 {
                    BudgetBurnChart(
                        expenses: filteredExpenses,
                        totalBudget: appViewModel.totalBudget,
                        currency: settingsViewModel.currency,
                        animate: $animateCharts
                    )
                    .padding(.horizontal, 20)
                }

                // Chart 3: Room progress
                if !appViewModel.projects.isEmpty {
                    RoomProgressChart(
                        projects: appViewModel.projects,
                        animate: $animateCharts
                    )
                    .padding(.horizontal, 20)
                }

                // Chart 4: Task donuts (two side by side)
                if !appViewModel.allTasks.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        TaskStatusDonut(tasks: appViewModel.allTasks, animate: $animateCharts)
                        TaskPriorityDonut(tasks: appViewModel.allTasks, animate: $animateCharts)
                    }
                    .padding(.horizontal, 20)
                }

                // Chart 5: Monthly spending bar
                if !filteredExpenses.isEmpty {
                    MonthlySpendingChart(
                        expenses: filteredExpenses,
                        currency: settingsViewModel.currency,
                        animate: $animateCharts
                    )
                    .padding(.horizontal, 20)
                }

                // Export
                Button(action: exportReport) {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                        .font(AppFonts.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.primary)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
            .padding(.top, 16)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { triggerAnimation() }
        .onDisappear { animateCharts = false }
        .sheet(isPresented: $showExport) {
            if let img = exportImage { ActivityShareSheet(items: [img]) }
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TimeFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedFilter = filter
                            showCustomPicker = (filter == .custom)
                        }
                        reAnimate()
                    }
                }
            }
        }
    }

    private var customDateCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("From").font(AppFonts.caption()).foregroundColor(AppColors.secondaryText)
                DatePicker("", selection: $customStart, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: customStart) { _ in reAnimate() }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("To").font(AppFonts.caption()).foregroundColor(AppColors.secondaryText)
                DatePicker("", selection: $customEnd, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: customEnd) { _ in reAnimate() }
            }
        }
        .cardStyle()
    }

    private func triggerAnimation() {
        animateCharts = false
        withAnimation(.easeInOut(duration: 0.6).delay(0.2)) { animateCharts = true }
    }

    private func reAnimate() {
        animateCharts = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { triggerAnimation() }
    }

    // MARK: - Export
    private func exportReport() {
        let view = ExportReportView(
            appViewModel: appViewModel,
            settingsViewModel: settingsViewModel,
            expenses: filteredExpenses
        )
        .frame(width: 390)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        if let img = renderer.uiImage {
            exportImage = img
            showExport = true
        }
    }
}

// MARK: - Report Summary Card (unchanged)
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
                ReportStatCell(title: "Projects", value: "\(appViewModel.projects.count)",
                               icon: "folder.fill", color: AppColors.primary)
                ReportStatCell(title: "Tasks", value: "\(appViewModel.allTasks.count)",
                               icon: "checkmark.circle.fill", color: AppColors.progress)
                ReportStatCell(title: "Total Spent",
                               value: appViewModel.totalSpent.currencyString(currency: currency),
                               icon: "dollarsign.circle.fill", color: AppColors.accent)
                ReportStatCell(title: "Contractors", value: "\(appViewModel.contractors.count)",
                               icon: "person.2.fill", color: Color(hex: "#9B51E0"))
            }
        }
        .cardStyle()
    }
}

struct ReportStatCell: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
                .frame(width: 36, height: 36).background(color.opacity(0.1)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(AppFonts.headline()).foregroundColor(AppColors.labelColor)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(title).font(AppFonts.caption()).foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color(.systemGray6)).cornerRadius(12)
    }
}

// MARK: - Chart 1: Budget Donut
struct BudgetDonutChart: View {
    let expenses: [Expense]
    let totalBudget: Double
    let currency: String
    @Binding var animate: Bool
    @State private var selectedCategory: ExpenseCategory? = nil

    var categoryTotals: [(category: ExpenseCategory, amount: Double, pct: Double)] {
        var t: [ExpenseCategory: Double] = [:]
        for e in expenses { t[e.category, default: 0] += e.amount }
        let total = t.values.reduce(0, +)
        return t.map { (category: $0.key, amount: $0.value, pct: total > 0 ? $0.value / total : 0) }
            .sorted { $0.amount > $1.amount }
    }

    var total: Double { expenses.reduce(0) { $0 + $1.amount } }

    var pctUsed: Double { totalBudget > 0 ? total / totalBudget : 0 }
    var pctColor: Color {
        pctUsed < 0.8 ? AppColors.progress : pctUsed < 1.0 ? AppColors.accent : AppColors.warning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Distribution")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))

            HStack(spacing: 20) {
                // Donut
                ZStack {
                    DonutChartShape(
                        segments: categoryTotals.map { DonutSegment(value: $0.amount, color: $0.category.color) },
                        animate: animate
                    )
                    .frame(width: 150, height: 150)

                    VStack(spacing: 2) {
                        Text(total.currencyString(currency: currency))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.primary)
                            .minimumScaleFactor(0.5).lineLimit(1)
                        if totalBudget > 0 {
                            Text("of \(totalBudget.currencyString(currency: currency))")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#8A94A6"))
                                .minimumScaleFactor(0.5).lineLimit(1)
                            Text(String(format: "%.0f%%", pctUsed * 100))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(pctColor)
                        }
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categoryTotals.prefix(5), id: \.category) { item in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = selectedCategory == item.category ? nil : item.category
                            }
                        }) {
                            HStack(spacing: 8) {
                                Circle().fill(item.category.color).frame(width: 10, height: 10)
                                Text(item.category.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#8A94A6")).lineLimit(1)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(item.amount.currencyString(currency: currency))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: "#2B2D42"))
                                        .lineLimit(1).minimumScaleFactor(0.5)
                                    Text("\(Int(item.pct * 100))%")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(hex: "#8A94A6"))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(4)
                        .background(selectedCategory == item.category ? item.category.color.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
}

// MARK: - Donut Helpers (kept from original)
struct DonutSegment {
    let value: Double
    let color: Color
}

struct DonutChartShape: View {
    let segments: [DonutSegment]
    let animate: Bool
    var total: Double { segments.reduce(0) { $0 + $1.value } }

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, seg in
                DonutSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: seg.color,
                    animate: animate
                )
            }
            Circle().fill(AppColors.cardBackground).frame(width: 90, height: 90)
        }
    }

    private func startAngle(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        return (segments.prefix(index).reduce(0) { $0 + $1.value } / total) * 360 - 90
    }
    private func endAngle(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        return (segments.prefix(index + 1).reduce(0) { $0 + $1.value } / total) * 360 - 90
    }
}

struct DonutSlice: View {
    let startAngle: Double; let endAngle: Double; let color: Color; let animate: Bool

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let r = min(geo.size.width, geo.size.height) / 2
                path.move(to: c)
                path.addArc(center: c, radius: r,
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(animate ? endAngle : startAngle),
                            clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
    }
}

// MARK: - Chart 2: Budget Burn Line Chart
struct BudgetBurnChart: View {
    let expenses: [Expense]
    let totalBudget: Double
    let currency: String
    @Binding var animate: Bool

    struct DailySpend: Identifiable {
        let id = UUID(); let date: Date; let cumulative: Double
    }

    var cumulativeData: [DailySpend] {
        let sorted = expenses.sorted { $0.date < $1.date }
        var cum = 0.0
        return sorted.map { e -> DailySpend in cum += e.amount; return DailySpend(date: e.date, cumulative: cum) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Burn")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))

            Chart {
                // Area fill
                ForEach(cumulativeData) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Spent", animate ? point.cumulative : 0)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [AppColors.primary.opacity(0.25), AppColors.primary.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)
                }
                // Actual spending line
                ForEach(cumulativeData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Spent", animate ? point.cumulative : 0)
                    )
                    .foregroundStyle(AppColors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
                // Budget line
                if totalBudget > 0 {
                    RuleMark(y: .value("Budget", totalBudget))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .foregroundStyle(AppColors.accent)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Budget")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(AppColors.accent)
                                .padding(.horizontal, 4)
                        }
                }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Color(.systemGray5))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#8A94A6"))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Color(.systemGray5))
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#8A94A6"))
                }
            }
            .animation(.easeInOut(duration: 0.6), value: animate)

            // Legend
            HStack(spacing: 16) {
                legendItem(color: AppColors.primary, label: "Actual spending", dashed: false)
                if totalBudget > 0 {
                    legendItem(color: AppColors.accent, label: "Budget", dashed: true)
                }
            }
        }
        .cardStyle()
    }

    private func legendItem(color: Color, label: String, dashed: Bool) -> some View {
        HStack(spacing: 6) {
            if dashed {
                Rectangle().fill(color).frame(width: 16, height: 2)
                    .overlay(Rectangle().fill(Color(.systemBackground)).frame(width: 4, height: 2).offset(x: -2))
            } else {
                Rectangle().fill(color).frame(width: 16, height: 2)
            }
            Text(label).font(.system(size: 11)).foregroundColor(Color(hex: "#8A94A6"))
        }
    }
}

// MARK: - Chart 3: Room Progress Bar Chart (Swift Charts)
struct RoomProgressChart: View {
    let projects: [Project]
    @Binding var animate: Bool
    @State private var expandedRoom: UUID? = nil

    struct RoomItem: Identifiable {
        let id: UUID; let name: String; let progress: Double
        let doneCount: Int; let inProgressCount: Int; let todoCount: Int
    }

    var roomItems: [RoomItem] {
        projects.flatMap { p in
            p.rooms.map { r in
                RoomItem(
                    id: r.id, name: r.name, progress: r.progress,
                    doneCount: r.tasks.filter { $0.status == .done }.count,
                    inProgressCount: r.tasks.filter { $0.status == .inProgress }.count,
                    todoCount: r.tasks.filter { $0.status == .todo }.count
                )
            }
        }
        .prefix(8).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Room Progress")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))

            if roomItems.isEmpty {
                Text("No rooms to display")
                    .font(AppFonts.body()).foregroundColor(AppColors.secondaryText)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(roomItems.enumerated()), id: \.element.id) { idx, room in
                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    expandedRoom = expandedRoom == room.id ? nil : room.id
                                }
                            }) {
                                HStack {
                                    Text(room.name)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color(hex: "#2B2D42")).lineLimit(1)
                                    Spacer()
                                    Text("\(Int(room.progress * 100))%")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(room.progress >= 1.0 ? AppColors.progress : AppColors.primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(hex: "#E9E1D3")).frame(height: 28)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppColors.progress)
                                        .frame(
                                            width: animate ? geo.size.width * CGFloat(room.progress) : 0,
                                            height: 28
                                        )
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(idx) * 0.08), value: animate)
                                }
                            }
                            .frame(height: 28)

                            // Expanded task breakdown
                            if expandedRoom == room.id {
                                HStack(spacing: 16) {
                                    taskDot(count: room.doneCount, label: "Done", color: AppColors.progress)
                                    taskDot(count: room.inProgressCount, label: "In Progress", color: AppColors.accent)
                                    taskDot(count: room.todoCount, label: "To Do", color: Color(hex: "#8A94A6"))
                                }
                                .padding(.horizontal, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func taskDot(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.system(size: 11)).foregroundColor(Color(hex: "#8A94A6"))
        }
    }
}

// MARK: - Chart 4a: Task Status Donut
struct TaskStatusDonut: View {
    let tasks: [TaskItem]
    @Binding var animate: Bool
    @State private var tooltip: String? = nil

    var todoCount:       Int { tasks.filter { $0.status == .todo }.count }
    var inProgressCount: Int { tasks.filter { $0.status == .inProgress }.count }
    var doneCount:       Int { tasks.filter { $0.status == .done }.count }
    var total: Int { tasks.count }

    var body: some View {
        VStack(spacing: 12) {
            Text("Tasks by Status")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                DonutChartShape(segments: [
                    DonutSegment(value: Double(doneCount),       color: AppColors.progress),
                    DonutSegment(value: Double(inProgressCount), color: AppColors.accent),
                    DonutSegment(value: Double(todoCount),       color: Color(hex: "#8A94A6"))
                ], animate: animate)
                .frame(width: 100, height: 100)

                VStack(spacing: 1) {
                    Text("\(total)").font(AppFonts.title2()).foregroundColor(AppColors.labelColor)
                    Text("tasks").font(AppFonts.caption()).foregroundColor(AppColors.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                donutLegendRow("Done",        count: doneCount,       color: AppColors.progress)
                donutLegendRow("In Progress", count: inProgressCount, color: AppColors.accent)
                donutLegendRow("To Do",       count: todoCount,       color: Color(hex: "#8A94A6"))
            }
        }
        .cardStyle(padding: 14)
    }

    private func donutLegendRow(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundColor(Color(hex: "#8A94A6"))
            Spacer()
            Text("\(count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))
        }
    }
}

// MARK: - Chart 4b: Task Priority Donut
struct TaskPriorityDonut: View {
    let tasks: [TaskItem]
    @Binding var animate: Bool

    var lowCount:      Int { tasks.filter { $0.priority == .low }.count }
    var mediumCount:   Int { tasks.filter { $0.priority == .medium }.count }
    var highCount:     Int { tasks.filter { $0.priority == .high }.count }
    var criticalCount: Int { tasks.filter { $0.priority == .critical }.count }
    var overdueCount:  Int { tasks.filter { $0.isOverdue }.count }

    var body: some View {
        VStack(spacing: 12) {
            Text("Tasks by Priority")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                DonutChartShape(segments: [
                    DonutSegment(value: Double(lowCount),      color: AppColors.progress),
                    DonutSegment(value: Double(mediumCount),   color: AppColors.primary),
                    DonutSegment(value: Double(highCount),     color: AppColors.accent),
                    DonutSegment(value: Double(criticalCount), color: AppColors.warning)
                ], animate: animate)
                .frame(width: 100, height: 100)

                VStack(spacing: 1) {
                    Text("\(overdueCount)")
                        .font(AppFonts.title2())
                        .foregroundColor(overdueCount > 0 ? AppColors.warning : AppColors.labelColor)
                    Text("overdue").font(AppFonts.caption()).foregroundColor(AppColors.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                donutLegendRow("Low",      count: lowCount,      color: AppColors.progress)
                donutLegendRow("Medium",   count: mediumCount,   color: AppColors.primary)
                donutLegendRow("High",     count: highCount,     color: AppColors.accent)
                if criticalCount > 0 {
                    donutLegendRow("Critical", count: criticalCount, color: AppColors.warning)
                }
            }
        }
        .cardStyle(padding: 14)
    }

    private func donutLegendRow(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundColor(Color(hex: "#8A94A6"))
            Spacer()
            Text("\(count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))
        }
    }
}

// MARK: - Chart 5: Monthly Spending Bar Chart
struct MonthlySpendingChart: View {
    let expenses: [Expense]
    let currency: String
    @Binding var animate: Bool

    struct MonthBar: Identifiable {
        let id = UUID(); let label: String; let month: Date; let amount: Double
    }

    var monthlyData: [MonthBar] {
        let cal = Calendar.current
        var grouped: [Date: Double] = [:]
        for exp in expenses {
            let comps = cal.dateComponents([.year, .month], from: exp.date)
            if let ms = cal.date(from: comps) { grouped[ms, default: 0] += exp.amount }
        }
        let fmt = DateFormatter(); fmt.dateFormat = "MMM yy"
        return grouped.map { MonthBar(label: fmt.string(from: $0.key), month: $0.key, amount: $0.value) }
            .sorted { $0.month < $1.month }
    }

    var average: Double {
        guard !monthlyData.isEmpty else { return 0 }
        return monthlyData.reduce(0) { $0 + $1.amount } / Double(monthlyData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Spending")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#2B2D42"))

            if monthlyData.isEmpty {
                Text("No data for selected period")
                    .font(AppFonts.body()).foregroundColor(AppColors.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    Chart {
                        ForEach(monthlyData) { bar in
                            BarMark(
                                x: .value("Month", bar.label),
                                y: .value("Amount", animate ? bar.amount : 0)
                            )
                            .foregroundStyle(AppColors.primary)
                            .cornerRadius(6)
                            .annotation(position: .top) {
                                if monthlyData.count <= 6 {
                                    Text(bar.amount.compactString)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color(hex: "#2B2D42"))
                                }
                            }
                        }
                        if average > 0 {
                            RuleMark(y: .value("Average", average))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .foregroundStyle(AppColors.accent)
                                .annotation(position: .trailing) {
                                    Text("Avg").font(.system(size: 9)).foregroundColor(AppColors.accent)
                                }
                        }
                    }
                    .frame(width: max(CGFloat(monthlyData.count) * 60, 280), height: 180)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#8A94A6"))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine().foregroundStyle(Color(.systemGray5))
                            AxisValueLabel()
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#8A94A6"))
                        }
                    }
                    .animation(.easeInOut(duration: 0.6), value: animate)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Export Report View (rendered to image)
struct ExportReportView: View {
    let appViewModel: AppViewModel
    let settingsViewModel: SettingsViewModel
    let expenses: [Expense]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Build Log — Report")
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.labelColor)
                    Text(Date().mediumDate)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.primary)
            }

            Divider()

            // Key stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                exportStat("Projects", value: "\(appViewModel.projects.count)")
                exportStat("Tasks", value: "\(appViewModel.allTasks.count)")
                exportStat("Total Spent", value: expenses.reduce(0) { $0 + $1.amount }.currencyString(currency: settingsViewModel.currency))
                exportStat("Budget", value: appViewModel.totalBudget.currencyString(currency: settingsViewModel.currency))
            }

            Divider()

            // Top categories
            Text("Top Expense Categories")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.labelColor)

            ForEach(topCategories, id: \.category) { item in
                HStack {
                    Circle().fill(item.category.color).frame(width: 10, height: 10)
                    Text(item.category.rawValue).font(AppFonts.body()).foregroundColor(AppColors.labelColor)
                    Spacer()
                    Text(item.amount.currencyString(currency: settingsViewModel.currency))
                        .font(AppFonts.body()).foregroundColor(AppColors.labelColor)
                }
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
    }

    private var topCategories: [(category: ExpenseCategory, amount: Double)] {
        var t: [ExpenseCategory: Double] = [:]
        for e in expenses { t[e.category, default: 0] += e.amount }
        return t.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(5).map { $0 }
    }

    private func exportStat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(AppFonts.title3()).foregroundColor(AppColors.primary).lineLimit(1).minimumScaleFactor(0.5)
            Text(label).font(AppFonts.caption()).foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
