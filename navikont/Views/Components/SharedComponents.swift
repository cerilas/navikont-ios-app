import SwiftUI

// MARK: - Animated Gradient Background

struct AnimatedMeshBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "0F0F23"),
                Color(hex: "1A1A3E"),
                Color(hex: "15152F"),
                Color(hex: "0F0F23")
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Floating Orbs

struct FloatingOrbs: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(NKColors.primaryGradientStart.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(
                    x: animate ? 40 : -40,
                    y: animate ? -30 : 30
                )
            
            Circle()
                .fill(NKColors.accentTeal.opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(
                    x: animate ? -50 : 50,
                    y: animate ? 60 : -60
                )
            
            Circle()
                .fill(NKColors.primaryGradientEnd.opacity(0.1))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(
                    x: animate ? 30 : -30,
                    y: animate ? 80 : -20
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Circular Progress Ring

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let gradient: LinearGradient
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, lineWidth: CGFloat = 6, size: CGFloat = 60, gradient: LinearGradient = NKColors.tealGradient) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.gradient = gradient
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(animatedProgress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundColor(NKColors.textPrimary)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Gradient Icon Badge

struct GradientIconBadge: View {
    let icon: String
    let gradient: LinearGradient
    let size: CGFloat
    
    init(icon: String, gradient: LinearGradient = NKColors.primaryGradient, size: CGFloat = 44) {
        self.icon = icon
        self.gradient = gradient
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3)
                .fill(gradient)
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text("\(displayValue)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(NKColors.textPrimary)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.caption)
                .foregroundColor(NKColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                displayValue = value
            }
        }
    }
}

// MARK: - Streak Flame

struct StreakBadge: View {
    let count: Int
    @State private var flicker = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundColor(NKColors.accentAmber)
                .scaleEffect(flicker ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: flicker)
            
            Text("\(count) gün")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(NKColors.accentAmber)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(NKColors.accentAmber.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(NKColors.accentAmber.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear { flicker = true }
    }
}

// MARK: - Pulse Dot

struct PulseDot: View {
    let color: Color
    @State private var pulse = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(pulse ? 2.5 : 1)
                    .opacity(pulse ? 0 : 0.6)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }
}
