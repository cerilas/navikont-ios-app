import SwiftUI

struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isVisible = false
    @State private var isBreathing = false
    @State private var indicatorPhase = 0

    var body: some View {
        ZStack {
            background
            ambientShapes

            VStack(spacing: 0) {
                Spacer()

                brand

                Spacer()

                VStack(spacing: 18) {
                    loadingIndicator

                    Text(AppStrings.t("Güvenli • Kişisel • Sizinle birlikte"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(.white.opacity(0.62))
                        .accessibilityHidden(true)
                }
                .padding(.bottom, 48)
                .opacity(isVisible ? 1 : 0)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AppStrings.t("NaviKont, Dijital Sağlık Asistanınız"))
        .onAppear(perform: startAnimations)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(hex: "10102B"),
                Color(hex: "17173B"),
                Color(hex: "20204A")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var ambientShapes: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(NKColors.primaryGradientStart.opacity(0.22))
                    .frame(width: proxy.size.width * 0.9)
                    .blur(radius: 74)
                    .position(
                        x: proxy.size.width * 0.16,
                        y: proxy.size.height * 0.22
                    )

                Circle()
                    .fill(NKColors.accentTeal.opacity(0.14))
                    .frame(width: proxy.size.width * 0.72)
                    .blur(radius: 68)
                    .position(
                        x: proxy.size.width * 0.88,
                        y: proxy.size.height * 0.78
                    )
            }
        }
        .accessibilityHidden(true)
    }

    private var brand: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.045), lineWidth: 1)
                    .frame(width: 420, height: 420)
                    .scaleEffect(isBreathing ? 1.05 : 0.92)

                Circle()
                    .stroke(.white.opacity(0.035), lineWidth: 1)
                    .frame(width: 286, height: 286)
                    .scaleEffect(isBreathing ? 0.94 : 1.04)

                Circle()
                    .fill(NKColors.primaryGradientStart.opacity(0.24))
                    .frame(width: 174, height: 174)
                    .blur(radius: 30)
                    .scaleEffect(isBreathing ? 1.08 : 0.92)

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .frame(width: 136, height: 136)
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    }

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 116, height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                    .shadow(color: NKColors.primaryGradientStart.opacity(0.45), radius: 24, y: 12)
            }
            .scaleEffect(isVisible ? 1 : 0.72)
            .opacity(isVisible ? 1 : 0)

            VStack(spacing: 9) {
                Text("NaviKont")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .tracking(-1.1)
                    .foregroundStyle(.white)

                Text(AppStrings.t("Dijital Sağlık Asistanınız"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .tracking(0.2)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .offset(y: isVisible ? 0 : 18)
            .opacity(isVisible ? 1 : 0)
        }
    }

    private var loadingIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(
                        index == indicatorPhase
                            ? AnyShapeStyle(NKColors.tealGradient)
                            : AnyShapeStyle(Color.white.opacity(0.2))
                    )
                    .frame(width: index == indicatorPhase ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.34, dampingFraction: 0.78), value: indicatorPhase)
            }
        }
        .accessibilityHidden(true)
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(360))
                indicatorPhase = (indicatorPhase + 1) % 3
            }
        }
    }

    private func startAnimations() {
        if reduceMotion {
            isVisible = true
            isBreathing = true
            return
        }

        withAnimation(.spring(response: 0.75, dampingFraction: 0.78)) {
            isVisible = true
        }

        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }
}

#Preview {
    SplashScreenView()
}
