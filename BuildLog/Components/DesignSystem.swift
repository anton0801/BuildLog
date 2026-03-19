import SwiftUI
import UIKit

// MARK: - App Colors
struct AppColors {
    static let background = Color(hex: "#F5F7FA")
    static let primary = Color(hex: "#2F80ED")
    static let accent = Color(hex: "#FF8A00")
    static let progress = Color(hex: "#27AE60")
    static let warning = Color(hex: "#EB5757")
    static let cardBackground = Color(.systemBackground)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    static let separator = Color(.separator)
    static let labelColor = Color(.label)
}

// MARK: - App Fonts
struct AppFonts {
    static func largeTitle() -> Font { .system(size: 30, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 24, weight: .bold, design: .rounded) }
    static func title2() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func title3() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 15, weight: .semibold, design: .default) }
    static func body() -> Font { .system(size: 14, weight: .regular, design: .default) }
    static func subheadline() -> Font { .system(size: 13, weight: .regular, design: .default) }
    static func caption() -> Font { .system(size: 12, weight: .regular, design: .default) }
    static func caption2() -> Font { .system(size: 11, weight: .regular, design: .default) }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isFullWidth: Bool = true

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 52)
            .padding(.horizontal, isFullWidth ? 0 : 24)
            .background(AppColors.primary)
            .cornerRadius(14)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isFullWidth: Bool = true

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .frame(height: 52)
                .padding(.horizontal, isFullWidth ? 0 : 24)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(14)
                .scaleEffect(isPressed ? 0.97 : 1.0)
        }
    }
}

// MARK: - Destructive Button
struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.warning)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.warning.opacity(0.1))
                .cornerRadius(14)
        }
    }
}

// MARK: - Card View Modifier
struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 60
    var color: Color = AppColors.progress
    var backgroundColor: Color = Color(.systemGray5)
    var showLabel: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress)
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.labelColor)
                    .fontWeight(.semibold)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var systemImage: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                if let icon = systemImage {
                    Image(systemName: icon)
                        .foregroundColor(AppColors.secondaryText)
                        .frame(width: 20)
                }
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(AppFonts.body())
                } else {
                    TextField(placeholder, text: $text)
                        .font(AppFonts.body())
                        .keyboardType(keyboardType)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(errorMessage != nil ? AppColors.warning : Color.clear, lineWidth: 1)
            )
            if let error = errorMessage {
                Text(error)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.warning)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Loading Shimmer View
struct ShimmerView: View {
    @State private var animating = false

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGray5),
                    Color(.systemGray4),
                    Color(.systemGray5)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 3)
            .offset(x: animating ? geo.size.width : -geo.size.width * 2)
            .animation(
                Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                value: animating
            )
        }
        .onAppear { animating = true }
        .clipped()
    }
}

struct LoadingCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 20)
                .overlay(ShimmerView())
                .cornerRadius(8)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(ShimmerView())
                .cornerRadius(8)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 14)
                .frame(width: 180)
                .overlay(ShimmerView())
                .cornerRadius(8)
        }
        .cardStyle()
    }
}

// MARK: - FAB Button
struct FABButton: View {
    let action: () -> Void
    var systemImage: String = "plus"
    var color: Color = AppColors.primary

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
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppFonts.caption2())
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.title3())
                .foregroundColor(AppColors.labelColor)
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(AppColors.secondaryText)
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.title3())
                    .foregroundColor(AppColors.labelColor)
                Text(subtitle)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            if let title = buttonTitle, let action = buttonAction {
                PrimaryButton(title: title, action: action, isFullWidth: false)
            }
        }
        .padding(40)
    }
}

// MARK: - Chip / Filter Button
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadline())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppColors.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : Color(.systemGray6))
                .cornerRadius(20)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}
