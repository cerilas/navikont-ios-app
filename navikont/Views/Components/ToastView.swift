import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let isSuccess: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if isPresented {
                    HStack(spacing: 12) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isSuccess ? .green : .red)
                        
                        Text(message)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, safeAreaInsets.top + 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .onAppear {
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(isSuccess ? .success : .error)
                        
                        // Auto dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.spring()) {
                                isPresented = false
                            }
                        }
                    }
                }
                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
        }
    }
    
    private var safeAreaInsets: UIEdgeInsets {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return .zero
        }
        return window.safeAreaInsets
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, isSuccess: Bool = true) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, message: message, isSuccess: isSuccess))
    }
}
