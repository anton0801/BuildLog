import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Binding var isPresented: Bool

    var preselectedProjectID: UUID? = nil

    @State private var name = ""
    @State private var category: ExpenseCategory = .other
    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedProjectID: UUID? = nil
    @State private var selectedRoomID: UUID? = nil
    @State private var notes = ""
    @State private var nameError: String? = nil
    @State private var amountError: String? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Expense Name", systemImage: "banknote")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "e.g., Paint purchase",
                            text: $name,
                            errorMessage: nameError
                        )
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Category", systemImage: "tag")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        category = cat
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(category == cat ? .white : cat.color)
                                            .frame(width: 36, height: 36)
                                            .background(category == cat ? cat.color : cat.color.opacity(0.1))
                                            .clipShape(Circle())
                                        Text(cat.rawValue)
                                            .font(AppFonts.caption2())
                                            .foregroundColor(category == cat ? cat.color : AppColors.secondaryText)
                                            .fontWeight(category == cat ? .semibold : .regular)
                                            .lineLimit(1)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(category == cat ? cat.color.opacity(0.05) : Color.clear)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Amount (\(settingsViewModel.currencySymbol))", systemImage: "dollarsign.circle")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "0.00",
                            text: $amount,
                            keyboardType: .decimalPad,
                            systemImage: "dollarsign",
                            errorMessage: amountError
                        )
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date", systemImage: "calendar")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(AppColors.primary)
                            .labelsHidden()
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Project
                    if preselectedProjectID == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Project (Optional)", systemImage: "folder")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Menu {
                                Button("None") { selectedProjectID = nil; selectedRoomID = nil }
                                ForEach(appViewModel.projects) { project in
                                    Button(project.name) {
                                        selectedProjectID = project.id
                                        selectedRoomID = nil
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedProjectID.flatMap { id in appViewModel.projects.first { $0.id == id }?.name } ?? "None")
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.labelColor)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Room
                    let rooms = (selectedProjectID ?? preselectedProjectID).flatMap { pid in
                        appViewModel.projects.first { $0.id == pid }
                    }?.rooms ?? []
                    if !rooms.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Room (Optional)", systemImage: "door.left.hand.open")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Menu {
                                Button("None") { selectedRoomID = nil }
                                ForEach(rooms) { room in
                                    Button(room.name) { selectedRoomID = room.id }
                                }
                            } label: {
                                HStack {
                                    Text(selectedRoomID.flatMap { rid in rooms.first { $0.id == rid }?.name } ?? "None")
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.labelColor)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (Optional)", systemImage: "note.text")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Add receipt info, vendor name...")
                                    .font(AppFonts.body())
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $notes)
                                .font(AppFonts.body())
                                .frame(minHeight: 80)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .opacity(notes.isEmpty ? 0.25 : 1)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 80)
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveExpense) {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            selectedProjectID = preselectedProjectID
        }
    }

    private func saveExpense() {
        nameError = nil
        amountError = nil

        guard !name.trimmed.isEmpty else {
            nameError = "Expense name is required"
            return
        }

        let a = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        if a <= 0 {
            amountError = "Enter a valid amount greater than 0"
            return
        }

        isSaving = true

        let expense = Expense(
            name: name.trimmed,
            category: category,
            amount: a,
            date: date,
            roomID: selectedRoomID,
            projectID: preselectedProjectID ?? selectedProjectID,
            notes: notes.trimmed
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appViewModel.addExpense(expense)
            isSaving = false
            isPresented = false
        }
    }
}
