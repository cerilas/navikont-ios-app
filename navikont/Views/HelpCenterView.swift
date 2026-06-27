import SwiftUI

struct HelpCenterView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var faqs: [FAQ] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    private var primaryColor: Color { Color(hex: "06B6D4") } // Cyan theme
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary(colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header Image / Icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "3B82F6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: "06B6D4").opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "questionmark.bubble.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        Text(AppStrings.t("Size Nasıl Yardımcı Olabiliriz?"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(NKColors.textPrimary(colorScheme))
                        
                        Text(AppStrings.t("Sıkça Sorulan Sorular (SSS)"))
                            .font(.system(size: 14))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // FAQ List
                    if isLoading {
                        ProgressView()
                            .padding(.top, 50)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    } else if faqs.isEmpty {
                        Text(AppStrings.t("Henüz hiç SSS eklenmemiş."))
                            .foregroundColor(NKColors.textTertiary(colorScheme))
                            .padding(.top, 50)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(faqs) { faq in
                                FAQRow(faq: faq)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Contact Support Button
                    VStack(spacing: 12) {
                        Text(AppStrings.t("Aradığınız cevabı bulamadınız mı?"))
                            .font(.system(size: 14))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                        
                        Button(action: {
                            // Support mail link
                            if let url = URL(string: "mailto:deniz@cerilas.com") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text(AppStrings.t("Destek Ekibiyle İletişime Geç"))
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(primaryColor)
                            .cornerRadius(25)
                            .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle(AppStrings.t("Yardım Merkezi"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchFAQs()
        }
    }
    
    private func fetchFAQs() async {
        do {
            let fetched = try await NetworkManager.shared.fetchFAQs()
            await MainActor.run {
                self.faqs = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = AppStrings.t("Sunucu hatası")
                self.isLoading = false
            }
        }
    }
}

struct FAQRow: View {
    @Environment(\.colorScheme) var colorScheme
    let faq: FAQ
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 16) {
                    Text(faq.question)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(NKColors.textPrimary(colorScheme))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(NKColors.textTertiary(colorScheme))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .background(NKColors.glassBackground(colorScheme))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(faq.answer)
                    .font(.system(size: 14))
                    .foregroundColor(NKColors.textSecondary(colorScheme))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(NKColors.glassBackground(colorScheme))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
        )
    }
}
