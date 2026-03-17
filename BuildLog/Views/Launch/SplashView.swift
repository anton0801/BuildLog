import SwiftUI

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var iconRotation: Double = -30
    @State private var backgroundOpacity: Double = 0

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1a5fb4"),
                    Color(hex: "#2F80ED"),
                    Color(hex: "#4a9af0")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(backgroundOpacity)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 90, height: 90)

                    ZStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.white)
                            .offset(y: -4)

                        Image(systemName: "hammer.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color(hex: "#FF8A00"))
                            .offset(x: 18, y: 14)
                            .rotationEffect(.degrees(45))
                    }
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .rotationEffect(.degrees(iconRotation))

                Spacer().frame(height: 36)

                // App Name
                VStack(spacing: 8) {
                    Text("RenovaTrack")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(titleOpacity)

                    Text("Plan and track your repair projects")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                        .opacity(subtitleOpacity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Bottom tagline
                VStack(spacing: 4) {
                    Text("Build Log")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))
                    Text("v1.0")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.3))
                }
                .opacity(subtitleOpacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Stage 1: Background fade in
        withAnimation(.easeIn(duration: 0.3)) {
            backgroundOpacity = 1
        }

        // Stage 2: Icon appears with spring
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconRotation = 0
        }

        // Stage 3: Title fades in
        withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
            titleOpacity = 1.0
        }

        // Stage 4: Subtitle fades in
        withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
            subtitleOpacity = 1.0
        }

        // Stage 5: Transition after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete()
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onComplete: {})
    }
}
