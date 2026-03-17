import SwiftUI

struct AddContractorView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var specialization: ContractorSpecialization = .general
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var rating = 0
    @State private var nameError: String? = nil
    @State private var phoneError: String? = nil
    @State private var emailError: String? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Full Name", systemImage: "person")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "e.g., John Smith",
                            text: $name,
                            systemImage: "person",
                            errorMessage: nameError
                        )
                    }

                    // Specialization
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Specialization", systemImage: "wrench.and.screwdriver")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(ContractorSpecialization.allCases, id: \.self) { spec in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        specialization = spec
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: spec.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(specialization == spec ? .white : AppColors.primary)
                                            .frame(width: 36, height: 36)
                                            .background(specialization == spec ? AppColors.primary : AppColors.primary.opacity(0.1))
                                            .clipShape(Circle())
                                        Text(spec.rawValue)
                                            .font(AppFonts.caption2())
                                            .foregroundColor(specialization == spec ? AppColors.primary : AppColors.secondaryText)
                                            .fontWeight(specialization == spec ? .semibold : .regular)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(specialization == spec ? AppColors.primary.opacity(0.05) : Color.clear)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // Phone
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Phone Number", systemImage: "phone")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "+1 555-0100",
                            text: $phone,
                            keyboardType: .phonePad,
                            systemImage: "phone",
                            errorMessage: phoneError
                        )
                    }

                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Email (Optional)", systemImage: "envelope")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "contractor@example.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            systemImage: "envelope",
                            errorMessage: emailError
                        )
                    }

                    // Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Rating", systemImage: "star")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        rating = star
                                    }
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 28))
                                        .foregroundColor(star <= rating ? Color(hex: "#FF8A00") : Color(.systemGray4))
                                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                                }
                            }
                            if rating > 0 {
                                Button(action: { rating = 0 }) {
                                    Text("Clear")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .padding(.leading, 8)
                            }
                            Spacer()
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (Optional)", systemImage: "note.text")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Work quality, pricing, availability...")
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
            .navigationTitle("Add Contractor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveContractor) {
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
    }

    private func saveContractor() {
        nameError = nil
        phoneError = nil
        emailError = nil

        guard !name.trimmed.isEmpty else {
            nameError = "Name is required"
            return
        }

        if !phone.isEmpty && !phone.trimmed.isValidPhone {
            phoneError = "Enter a valid phone number"
            return
        }

        if !email.isEmpty && !email.trimmed.isValidEmail {
            emailError = "Enter a valid email address"
            return
        }

        isSaving = true

        let contractor = Contractor(
            name: name.trimmed,
            specialization: specialization,
            phone: phone.trimmed,
            email: email.trimmed,
            notes: notes.trimmed,
            rating: rating
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appViewModel.addContractor(contractor)
            isSaving = false
            isPresented = false
        }
    }
}
