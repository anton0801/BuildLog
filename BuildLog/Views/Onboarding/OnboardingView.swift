import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    @State private var dragOffset: CGFloat = 0

    var onComplete: () -> Void

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Plan Your Renovation",
            subtitle: "Create projects, add rooms, and organize every step of your renovation from start to finish.",
            illustration: "OnboardingIllustration1",
            accentColor: Color(hex: "#2F80ED")
        ),
        OnboardingPage(
            title: "Track Every Detail",
            subtitle: "Log tasks, materials, and progress photos. Never miss a deadline or forget a detail.",
            illustration: "OnboardingIllustration2",
            accentColor: Color(hex: "#27AE60")
        ),
        OnboardingPage(
            title: "Control Your Budget",
            subtitle: "Track expenses by category, monitor your budget, and generate detailed reports.",
            illustration: "OnboardingIllustration3",
            accentColor: Color(hex: "#FF8A00")
        )
    ]

    var body: some View {
        ZStack {
            pages[currentPage].accentColor
                .opacity(0.07)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 50)

                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], pageIndex: index, currentPage: $currentPage)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)

                // Dots and Buttons
                VStack(spacing: 24) {
                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(index == currentPage ? pages[currentPage].accentColor : Color(.systemGray4))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentPage -= 1
                                }
                            }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(pages[currentPage].accentColor)
                                    .frame(width: 52, height: 52)
                                    .background(pages[currentPage].accentColor.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                    .font(AppFonts.headline())
                                Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(pages[currentPage].accentColor)
                            .cornerRadius(16)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        onComplete()
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let illustration: String
    let accentColor: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    @Binding var currentPage: Int

    @State private var animate = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Illustration
            Group {
                if pageIndex == 0 {
                    PlanIllustrationView(color: page.accentColor, animate: $animate)
                } else if pageIndex == 1 {
                    TrackIllustrationView(color: page.accentColor, animate: $animate)
                } else {
                    BudgetIllustrationView(color: page.accentColor, animate: $animate)
                }
            }
            .frame(height: 280)

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(AppFonts.largeTitle())
                    .foregroundColor(AppColors.labelColor)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animate = true
            }
        }
        .onChange(of: currentPage) { _ in
            animate = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animate = true
            }
        }
    }
}

// MARK: - Illustration 1: Plan
struct PlanIllustrationView: View {
    let color: Color
    @Binding var animate: Bool

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: 240, height: 240)
                .scaleEffect(animate ? 1 : 0.7)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animate)

            VStack(spacing: 16) {
                // Floor plan grid
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 2)
                            .frame(width: 70, height: 55)
                            .overlay(
                                Image(systemName: "sofa")
                                    .font(.system(size: 20))
                                    .foregroundColor(color.opacity(0.7))
                            )
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 2)
                            .frame(width: 55, height: 55)
                            .overlay(
                                Image(systemName: "bed.double")
                                    .font(.system(size: 16))
                                    .foregroundColor(color.opacity(0.7))
                            )
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 2)
                            .frame(width: 55, height: 45)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 16))
                                    .foregroundColor(color.opacity(0.7))
                            )
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 2)
                            .frame(width: 70, height: 45)
                            .overlay(
                                Image(systemName: "shower")
                                    .font(.system(size: 16))
                                    .foregroundColor(color.opacity(0.7))
                            )
                    }
                }
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animate)

                // House icon
                Image(systemName: "house.fill")
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: animate)
            }
        }
    }
}

// MARK: - Illustration 2: Track
struct TrackIllustrationView: View {
    let color: Color
    @Binding var animate: Bool

    let tasks: [(title: String, done: Bool, delay: Double)] = [
        ("Install flooring", true, 0.1),
        ("Paint walls", true, 0.2),
        ("Add lighting", false, 0.3),
        ("Final inspection", false, 0.4)
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: 240, height: 240)
                .scaleEffect(animate ? 1 : 0.7)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)

            VStack(spacing: 12) {
                ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                    HStack(spacing: 12) {
                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(task.done ? color : Color(.systemGray4))
                            .scaleEffect(animate ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(task.delay), value: animate)

                        Text(task.title)
                            .font(AppFonts.subheadline())
                            .foregroundColor(task.done ? AppColors.labelColor : AppColors.secondaryText)
                            .strikethrough(task.done)

                        Spacer()
                    }
                    .frame(width: 200)
                    .offset(x: animate ? 0 : 30)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(task.delay), value: animate)
                }
            }
        }
    }
}

// MARK: - Illustration 3: Budget
struct BudgetIllustrationView: View {
    let color: Color
    @Binding var animate: Bool

    let bars: [(label: String, value: CGFloat, color: Color)] = [
        ("Materials", 0.8, Color(hex: "#2F80ED")),
        ("Labor", 0.6, Color(hex: "#FF8A00")),
        ("Delivery", 0.4, Color(hex: "#27AE60")),
        ("Tools", 0.3, Color(hex: "#EB5757"))
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: 240, height: 240)
                .scaleEffect(animate ? 1 : 0.7)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)

            VStack(spacing: 10) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                    HStack(spacing: 10) {
                        Text(bar.label)
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .frame(width: 60, alignment: .trailing)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 12)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(bar.color)
                                    .frame(width: animate ? geo.size.width * bar.value : 0, height: 12)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1 + 0.2), value: animate)
                            }
                        }
                        .frame(height: 12)
                    }
                    .frame(width: 200)
                    .offset(y: animate ? 0 : 10)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: animate)
                }

                // Total
                HStack {
                    Spacer()
                    Text("Total: $23,500")
                        .font(AppFonts.headline())
                        .foregroundColor(color)
                }
                .frame(width: 200)
                .opacity(animate ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.6), value: animate)
            }
        }
    }
}
