import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showDashboard = false
    
    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                DashboardView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                LoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: authService.isAuthenticated)
        .preferredColorScheme(.dark)
    }
}
