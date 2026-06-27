import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var showingAlert = false
    
    // UI Helpers
    private var primaryColor: Color { Color(hex: "06B6D4") } // Cyan theme
    
    private var isFormValid: Bool {
        !oldPassword.isEmpty && !newPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 6
    }
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary(colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header Image / Icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        Text(AppStrings.t("Güvenlik Ayarları"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(NKColors.textPrimary(colorScheme))
                        
                        Text(AppStrings.t("Hesap güvenliğiniz için şifrenizi güçlü ve benzersiz tutun."))
                            .font(.system(size: 14))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        SecureFieldRow(icon: "lock.fill", placeholder: AppStrings.t("Eski Şifre"), text: $oldPassword)
                        
                        SecureFieldRow(icon: "key.fill", placeholder: AppStrings.t("Yeni Şifre"), text: $newPassword)
                        
                        SecureFieldRow(icon: "key.fill", placeholder: AppStrings.t("Yeni Şifre (Tekrar)"), text: $confirmPassword)
                        
                        // Validation Hint
                        if !newPassword.isEmpty && newPassword != confirmPassword {
                            Text(AppStrings.t("Yeni şifreler eşleşmiyor"))
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 16)
                        } else if !newPassword.isEmpty && newPassword.count < 6 {
                            Text(AppStrings.t("Şifre en az 6 karakter olmalıdır"))
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 16)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(NKColors.glassBackground(colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                    )
                    
                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                    }
                    
                    // Submit Button
                    Button(action: changePasswordTapped) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(primaryColor.opacity(0.5))
                                .cornerRadius(27)
                        } else {
                            Text(AppStrings.t("Şifreyi Güncelle"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(isFormValid ? primaryColor : Color.gray.opacity(0.5))
                                .cornerRadius(27)
                                .shadow(color: isFormValid ? primaryColor.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.top, 10)
                    
                }
                .padding(20)
            }
        }
        .navigationTitle("Şifre Değiştir")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(AppStrings.t("Başarılı")),
                message: Text(successMessage ?? "Şifreniz güncellendi."),
                dismissButton: .default(Text(AppStrings.t("Tamam"))) {
                    dismiss()
                }
            )
        }
    }
    
    private func changePasswordTapped() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let message = try await authService.changePassword(oldPassword: oldPassword, newPassword: newPassword)
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = message
                    self.showingAlert = true
                    
                    // Optionally log out user here if requested by user. 
                    // But in this implementation plan we will just stay logged in unless requested otherwise.
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.errorDescription
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct SecureFieldRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(NKColors.textTertiary(colorScheme))
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .font(.system(size: 16))
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(16)
        .background(NKColors.glassBackground(colorScheme))
        .cornerRadius(12)
    }
}
