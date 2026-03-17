import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var selectedCategory: ExpenseCategory? = nil
    @State private var showAddExpense = false

    var filteredExpenses: [Expense] {
        if let cat = selectedCategory {
            return appViewModel.expenses.filter { $0.category == cat }
        }
        return appViewModel.expenses.sorted { $0.date > $1.date }
    }

    var totalFiltered: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = nil
                            }
                        }
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                if appViewModel.expenses.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "dollarsign.circle",
                        title: "No Expenses Yet",
                        subtitle: "Track your renovation expenses to stay within budget.",
                        buttonTitle: "Add Expense",
                        buttonAction: { showAddExpense = true }
                    )
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary Card with Bar Chart
                            ExpenseSummaryCard(
                                expenses: appViewModel.expenses,
                                currency: settingsViewModel.currency
                            )
                            .padding(.horizontal, 20)

                            // Filtered total
                            if let cat = selectedCategory {
                                HStack {
                                    Text("\(cat.rawValue) Total:")
                                        .font(AppFonts.subheadline())
                                        .foregroundColor(AppColors.secondaryText)
                                    Spacer()
                                    Text(totalFiltered.currencyString(currency: settingsViewModel.currency))
                                        .font(AppFonts.headline())
                                        .foregroundColor(cat.color)
                                }
                                .padding(.horizontal, 20)
                            }

                            // Expense list
                            if filteredExpenses.isEmpty {
                                EmptyStateView(
                                    icon: "magnifyingglass",
                                    title: "No Expenses",
                                    subtitle: "No expenses in this category yet."
                                )
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(filteredExpenses) { expense in
                                        ExpenseCard(expense: expense, currency: settingsViewModel.currency)
                                            .padding(.horizontal, 20)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    appViewModel.deleteExpense(expense)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, 12)
                    }
                    .background(AppColors.background)
                }
            }
            .background(AppColors.background.ignoresSafeArea())

            FABButton(action: { showAddExpense = true })
                .padding(.trailing, 24)
                .padding(.bottom, 100)
        }
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(isPresented: $showAddExpense)
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
        }
    }
}

// MARK: - Expense Summary Card
struct ExpenseSummaryCard: View {
    let expenses: [Expense]
    let currency: String
    @State private var animate = false

    var categoryTotals: [(category: ExpenseCategory, amount: Double)] {
        var totals: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            totals[expense.category, default: 0] += expense.amount
        }
        return totals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    var maxAmount: Double {
        categoryTotals.map { $0.amount }.max() ?? 1
    }

    var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Spent")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                    Text(total.currencyString(currency: currency))
                        .font(AppFonts.title2())
                        .foregroundColor(AppColors.labelColor)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.primary)
            }

            Divider()

            // Bar Chart
            VStack(spacing: 10) {
                ForEach(categoryTotals.prefix(5), id: \.category) { item in
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 11))
                                .foregroundColor(item.category.color)
                            Text(item.category.rawValue)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(width: 90, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 10)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.category.color)
                                    .frame(
                                        width: animate ? geo.size.width * CGFloat(item.amount / maxAmount) : 0,
                                        height: 10
                                    )
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animate)
                            }
                        }
                        .frame(height: 10)

                        Text(item.amount.currencyString(currency: currency))
                            .font(AppFonts.caption())
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.labelColor)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
        }
        .cardStyle()
        .onAppear {
            withAnimation {
                animate = true
            }
        }
    }
}

// MARK: - Expense Card
struct ExpenseCard: View {
    let expense: Expense
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    BadgeView(text: expense.category.rawValue, color: expense.category.color)
                    Text(expense.date.shortDate)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
            }

            Spacer()

            Text(expense.amount.currencyString(currency: currency))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.labelColor)
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
