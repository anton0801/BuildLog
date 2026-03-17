import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isSignIn = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var nameError: String? = nil
    @State private var confirmError: String? = nil
    @State private var generalError: String? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var formOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "house.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    Text("RenovaTrack")
                        .font(AppFonts.largeTitle())
                        .foregroundColor(AppColors.labelColor)
                    Text(isSignIn ? "Welcome back!" : "Create your account")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                // Toggle
                HStack(spacing: 0) {
                    AuthToggleButton(title: "Sign In", isSelected: isSignIn) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isSignIn = true
                            clearErrors()
                        }
                    }
                    AuthToggleButton(title: "Create Account", isSelected: !isSignIn) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isSignIn = false
                            clearErrors()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                // Form
                VStack(spacing: 16) {
                    if !isSignIn {
                        CustomTextField(
                            placeholder: "Full Name",
                            text: $name,
                            systemImage: "person",
                            errorMessage: nameError
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }

                    CustomTextField(
                        placeholder: "Email Address",
                        text: $email,
                        keyboardType: .emailAddress,
                        systemImage: "envelope",
                        errorMessage: emailError
                    )

                    CustomTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        systemImage: "lock",
                        errorMessage: passwordError
                    )

                    if !isSignIn {
                        CustomTextField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            isSecure: true,
                            systemImage: "lock.shield",
                            errorMessage: confirmError
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }

                    if let error = generalError {
                        Text(error)
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.warning)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.warning.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 24)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSignIn)

                // Forgot Password (Sign In only)
                if isSignIn {
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showForgotPassword()
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                // Main Action Button
                VStack(spacing: 12) {
                    PrimaryButton(
                        title: isSignIn ? "Sign In" : "Create Account",
                        action: isSignIn ? performSignIn : performSignUp,
                        isLoading: isLoading
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Divider
//                    HStack {
//                        Rectangle().fill(AppColors.separator).frame(height: 1)
//                        Text("or")
//                            .font(AppFonts.caption())
//                            .foregroundColor(AppColors.secondaryText)
//                            .padding(.horizontal, 12)
//                        Rectangle().fill(AppColors.separator).frame(height: 1)
//                    }
//                    .padding(.horizontal, 24)
//
//                    // Apple Sign In
//                    SignInWithAppleButton(.signIn) { request in
//                        request.requestedScopes = [.fullName, .email]
//                    } onCompletion: { result in
//                        handleAppleSignIn(result: result)
//                    }
//                    .frame(height: 52)
//                    .cornerRadius(14)
//                    .padding(.horizontal, 24)
//                    .if(traitCollection.userInterfaceStyle == .dark) { view in
//                        view.colorScheme(.dark)
//                    }
                }

                // Demo Mode
                Button(action: { signInWithDemo() }) {
                    Text("Continue as Demo")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.top, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private var traitCollection: UITraitCollection {
        UITraitCollection.current
    }

    // MARK: - Validation
    private func validateSignIn() -> Bool {
        var valid = true
        clearErrors()

        if email.trimmed.isEmpty {
            emailError = "Email is required"
            valid = false
        } else if !email.trimmed.isValidEmail {
            emailError = "Enter a valid email address"
            valid = false
        }

        if password.isEmpty {
            passwordError = "Password is required"
            valid = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            valid = false
        }

        return valid
    }

    private func validateSignUp() -> Bool {
        var valid = true
        clearErrors()

        if name.trimmed.isEmpty {
            nameError = "Name is required"
            valid = false
        }

        if email.trimmed.isEmpty {
            emailError = "Email is required"
            valid = false
        } else if !email.trimmed.isValidEmail {
            emailError = "Enter a valid email address"
            valid = false
        }

        if password.isEmpty {
            passwordError = "Password is required"
            valid = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            valid = false
        }

        if confirmPassword != password {
            confirmError = "Passwords do not match"
            valid = false
        }

        return valid
    }

    private func clearErrors() {
        emailError = nil
        passwordError = nil
        nameError = nil
        confirmError = nil
        generalError = nil
    }

    // MARK: - Actions
    private func performSignIn() {
        guard validateSignIn() else { return }
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            let user = User(name: "User", email: email.trimmed)
            appViewModel.signIn(user: user)
        }
    }

    private func performSignUp() {
        guard validateSignUp() else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            let user = User(name: name.trimmed, email: email.trimmed)
            appViewModel.signIn(user: user)
        }
    }

    private func signInWithDemo() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            let user = User(name: "Demo User", email: "demo@renovatrack.com")
            appViewModel.signIn(user: user)
        }
    }

    private func showForgotPassword() {
        alertMessage = "A password reset link has been sent to your email address."
        showingAlert = true
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                let firstName = credential.fullName?.givenName ?? ""
                let lastName = credential.fullName?.familyName ?? ""
                let fullName = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
                let email = credential.email ?? "apple@user.com"
                let user = User(name: fullName.isEmpty ? "Apple User" : fullName, email: email)
                appViewModel.signIn(user: user)
            }
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                generalError = "Apple Sign In failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Auth Toggle Button
struct AuthToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadline())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? AppColors.primary : AppColors.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(isSelected ? Color(.systemBackground) : Color.clear)
                .cornerRadius(10)
                .padding(4)
        }
    }
}
