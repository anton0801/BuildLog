import SwiftUI

struct CreateProjectView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var projectType: ProjectType = .apartment
    @State private var startDate = Date()
    @State private var budget = ""
    @State private var notes = ""

    @State private var nameError: String? = nil
    @State private var budgetError: String? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Project Name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Project Name", systemImage: "folder")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "e.g., Apartment Renovation 2024",
                            text: $name,
                            errorMessage: nameError
                        )
                    }

                    // Project Type
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Project Type", systemImage: "tag")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ProjectType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            projectType = type
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 22))
                                                .foregroundColor(projectType == type ? .white : AppColors.primary)
                                                .frame(width: 48, height: 48)
                                                .background(projectType == type ? AppColors.primary : AppColors.primary.opacity(0.1))
                                                .clipShape(Circle())
                                            Text(type.rawValue)
                                                .font(AppFonts.caption())
                                                .foregroundColor(projectType == type ? AppColors.primary : AppColors.secondaryText)
                                                .fontWeight(projectType == type ? .semibold : .regular)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .frame(width: 72)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }

                    // Start Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Start Date", systemImage: "calendar")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(AppColors.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Budget
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Total Budget", systemImage: "banknote")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "0.00",
                            text: $budget,
                            keyboardType: .decimalPad,
                            systemImage: "dollarsign",
                            errorMessage: budgetError
                        )
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (Optional)", systemImage: "note.text")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Add project description, goals, or notes...")
                                    .font(AppFonts.body())
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $notes)
                                .font(AppFonts.body())
                                .frame(minHeight: 100)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .opacity(notes.isEmpty ? 0.25 : 1)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 100)
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveProject) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
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
    }

    private func validate() -> Bool {
        var valid = true
        nameError = nil
        budgetError = nil

        if name.trimmed.isEmpty {
            nameError = "Project name is required"
            valid = false
        }

        if let b = Double(budget.replacingOccurrences(of: ",", with: ".")), b <= 0 {
            budgetError = "Budget must be greater than 0"
            valid = false
        } else if !budget.isEmpty {
            if Double(budget.replacingOccurrences(of: ",", with: ".")) == nil {
                budgetError = "Enter a valid amount"
                valid = false
            }
        } else {
            budgetError = "Budget is required"
            valid = false
        }

        return valid
    }

    private func saveProject() {
        guard validate() else { return }
        isSaving = true

        let budgetValue = Double(budget.replacingOccurrences(of: ",", with: ".")) ?? 0

        let project = Project(
            name: name.trimmed,
            type: projectType,
            status: .planning,
            startDate: startDate,
            budget: budgetValue,
            notes: notes.trimmed
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appViewModel.addProject(project)
            isSaving = false
            isPresented = false
        }
    }
}
