import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showContent = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var formOffset: CGFloat = 40
    @State private var formOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedMeshBackground()
            FloatingOrbs()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 80)
                    
                    // Logo & Branding
                    VStack(spacing: 16) {
                        ZStack {
                            // Glow
                            Circle()
                                .fill(NKColors.primaryGradientStart.opacity(0.25))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)
                            
                            // App Logo
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 88, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: NKColors.primaryGradientStart.opacity(0.4), radius: 20, y: 10)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        
                        VStack(spacing: 6) {
                            Text(AppStrings.t("NaviKont"))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(NKColors.textPrimary(colorScheme))
                            
                            Text(AppStrings.t("Dijital Sağlık Asistanınız"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(NKColors.textSecondary(colorScheme))
                        }
                        .opacity(logoOpacity)
                    }
                    .padding(.bottom, 50)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Label(AppStrings.t("E-posta"), systemImage: "envelope.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary(colorScheme))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(NKColors.textTertiary(colorScheme))
                                
                                TextField("", text: $email, prompt: Text(AppStrings.t("ornek@navikont.com")).foregroundColor(NKColors.textTertiary(colorScheme)))
                                    .foregroundColor(NKColors.textPrimary(colorScheme))
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(NKColors.glassBackground(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Label(AppStrings.t("Şifre"), systemImage: "lock.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary(colorScheme))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(NKColors.textTertiary(colorScheme))
                                
                                SecureField("", text: $password, prompt: Text(AppStrings.t("••••••••")).foregroundColor(NKColors.textTertiary(colorScheme)))
                                    .foregroundColor(NKColors.textPrimary(colorScheme))
                                    .textContentType(.password)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(NKColors.glassBackground(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Forgot password
                        HStack {
                            Spacer()
                            Button(action: {}) {
                                Text(AppStrings.t("Şifremi Unuttum"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(NKColors.primaryGradientStart)
                            }
                        }
                        .padding(.top, -4)
                        
                        // Login button
                        Button(action: {
                            performLogin()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(NKColors.primaryGradient)
                                    .frame(height: 56)
                                    .shadow(color: NKColors.primaryGradientStart.opacity(0.4), radius: 16, y: 8)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.1)
                                } else {
                                    HStack(spacing: 10) {
                                        Text(AppStrings.t("Giriş Yap"))
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        .padding(.top, 8)
                        
                        // Error message
                        if let error = authService.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(NKColors.danger)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(NKColors.danger.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(NKColors.danger.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 28)
                    .offset(y: formOffset)
                    .opacity(formOpacity)
                    
                    Spacer(minLength: 60)
                    
                    // Footer
                    VStack(spacing: 6) {
                        Text(AppStrings.t("DiGA Sertifikalı Sağlık Uygulaması"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(NKColors.textTertiary(colorScheme))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 10))
                            Text(AppStrings.t("Verileriniz KVKK kapsamında korunmaktadır"))
                                .font(.system(size: 10))
                        }
                        .foregroundColor(NKColors.textTertiary(colorScheme).opacity(0.7))
                    }
                    .opacity(formOpacity)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            animateEntrance()
        }
        .onChange(of: authService.isAuthenticated) {
            isLoading = false
        }
        .onChange(of: authService.isLoading) {
            isLoading = authService.isLoading
        }
    }
    
    private func animateEntrance() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5)) {
            formOffset = 0
            formOpacity = 1.0
        }
    }
    
    private func performLogin() {
        withAnimation(.spring(response: 0.3)) {
            isLoading = true
        }
        authService.login(username: email, password: password)
    }
}
