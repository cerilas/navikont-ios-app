import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthService
    @ObservedObject var themeManager = ThemeManager.shared
    @AppStorage("app_language") private var appLanguage: String = "system"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    
    // UI Helpers
    private var primaryColor: Color { Color(hex: "06B6D4") } // Cyan theme
    
    var body: some View {
        NavigationView {
            ZStack {
                NKColors.bgPrimary(colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Profile Section
                        VStack(spacing: 16) {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                ZStack {
                                    if let base64String = authService.currentUser?.profileImage,
                                       let imageData = Data(base64Encoded: base64String),
                                       let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                            .shadow(color: Color(hex: "06B6D4").opacity(0.3), radius: 10, x: 0, y: 5)
                                    } else {
                                        Circle()
                                            .fill(LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "3B82F6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 90, height: 90)
                                            .shadow(color: Color(hex: "06B6D4").opacity(0.3), radius: 10, x: 0, y: 5)
                                        
                                        Text(String((authService.currentUser?.firstName ?? "H").prefix(1)))
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if isUploadingImage {
                                        ZStack {
                                            Circle().fill(NKColors.cardShadow(colorScheme))
                                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }
                                        .frame(width: 90, height: 90)
                                    } else {
                                        // Edit badge
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(primaryColor)
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            .offset(x: 32, y: 32)
                                    }
                                }
                            }
                            .disabled(isUploadingImage)
                            
                            VStack(spacing: 4) {
                                Text(authService.currentUser?.fullName ?? "Misafir Hasta")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(NKColors.textPrimary(colorScheme))
                                
                                Text(authService.currentUser?.email ?? "email@example.com")
                                    .font(.system(size: 15))
                                    .foregroundColor(NKColors.textSecondary(colorScheme))
                            }
                        }
                        .padding(.top, 20)
                        
                        // Theme Picker Section
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .foregroundColor(primaryColor)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(AppStrings.t("Görünüm"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(NKColors.textSecondary(colorScheme))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            HStack(spacing: 8) {
                                ForEach(ThemeMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            themeManager.currentMode = mode
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: mode.icon)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(themeManager.currentMode == mode ? .white : NKColors.textSecondary(colorScheme))
                                            Text(mode.displayName)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(themeManager.currentMode == mode ? .white : NKColors.textSecondary(colorScheme))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(themeManager.currentMode == mode
                                                    ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "3B82F6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                    : AnyShapeStyle(NKColors.glassBackground(colorScheme)))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(themeManager.currentMode == mode ? Color.clear : NKColors.glassBorder(colorScheme), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Language Picker Section
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(primaryColor)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(AppStrings.t("Uygulama Dili"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(NKColors.textSecondary(colorScheme))
                                Spacer()
                                
                                Picker(AppStrings.t("Dil"), selection: $appLanguage) {
                                    Text(AppStrings.t("Sistem")).tag("system")
                                    Text("Türkçe").tag("tr")
                                    Text("English").tag("en")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .tint(primaryColor)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(NKColors.glassBackground(colorScheme))
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Settings List
                        VStack(spacing: 20) {
                            ProfileNavigationRow(
                                icon: "heart.text.square.fill", color: primaryColor,
                                title: AppStrings.t("Sağlık ve Fiziksel Bilgiler"), subtitle: AppStrings.t("Boy, kilo, kan grubu"),
                                destination: AnyView(HealthProfileView())
                            )
                            
                            ProfileNavigationRow(
                                icon: "bell.badge.fill", color: .orange,
                                title: AppStrings.t("Bildirimler"), subtitle: AppStrings.t("Açık"),
                                destination: AnyView(NotificationSettingsView())
                            )
                            
                            ProfileNavigationRow(
                                icon: "lock.shield.fill", color: .green,
                                title: AppStrings.t("Şifre ve Güvenlik"), subtitle: AppStrings.t("Şifre değiştir"),
                                destination: AnyView(ChangePasswordView())
                            )
                            ProfileNavigationRow(
                                icon: "doc.text.fill", color: .blue,
                                title: AppStrings.t("Gizlilik Politikası"), subtitle: AppStrings.t("KVKK metni"),
                                destination: AnyView(PrivacyPolicyView())
                            )
                            ProfileNavigationRow(
                                icon: "questionmark.circle.fill", color: .purple,
                                title: AppStrings.t("Yardım Merkezi"), subtitle: AppStrings.t("Sık sorulan sorular"),
                                destination: AnyView(HelpCenterView())
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                        
                        // Logout Button
                        Button(action: {
                            withAnimation(.spring()) {
                                authService.logout()
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                                Text(AppStrings.t("Çıkış Yap"))
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.9))
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        
                        Text(AppStrings.t("NaviKont v1.0.0"))
                            .font(.system(size: 13))
                            .foregroundColor(NKColors.textTertiary(colorScheme))
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Profilim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(NKColors.textTertiary(colorScheme))
                    }
                }
            }
        }
        .preferredColorScheme(themeManager.currentMode.colorScheme)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(AppStrings.t("Bilgi")), message: Text(alertMessage), dismissButton: .default(Text(AppStrings.t("Tamam"))))
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await uploadImage(image: uiImage)
                }
            }
        }
    }
    
    private func uploadImage(image: UIImage) async {
        // Resize image to max 300x300 to save DB space
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 300, height: 300))
        
        // Compress to JPEG and convert to Base64
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.6) else { return }
        let base64String = jpegData.base64EncodedString()
        
        isUploadingImage = true
        
        do {
            try await authService.uploadProfileImage(base64String: base64String)
            isUploadingImage = false
        } catch {
            isUploadingImage = false
            showAlert(message: AppStrings.t("Resim yüklenirken bir hata oluştu") + ": \(error.localizedDescription)")
        }
    }
    
    // Simple image resizer
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        if ratio >= 1.0 { return image } // No need to upscale
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(NKColors.textPrimary(colorScheme))
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(NKColors.textTertiary(colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NKColors.textTertiary(colorScheme))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(NKColors.glassBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
            )
        }
    }
}

struct ProfileNavigationRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let destination: AnyView
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(NKColors.textPrimary(colorScheme))
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(NKColors.textTertiary(colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NKColors.textTertiary(colorScheme))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(NKColors.glassBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
