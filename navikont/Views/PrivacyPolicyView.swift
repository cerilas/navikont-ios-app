import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var consents: [ConsentDocument] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    // UI Helpers
    private var primaryColor: Color { Color(hex: "06B6D4") } // Cyan theme
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary(colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    } else if consents.isEmpty {
                        Text(AppStrings.t("Kayıt bulunamadı."))
                            .foregroundColor(NKColors.textTertiary(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                    } else {
                        ForEach(consents) { consent in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(consent.title)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(NKColors.textPrimary(colorScheme))
                                
                                if let pubDate = consent.publishedAt {
                                    Text(AppStrings.t("Son Güncelleme:") + " \(formattedDate(pubDate))")
                                        .font(.system(size: 13))
                                        .foregroundColor(NKColors.textTertiary(colorScheme))
                                }
                                
                                Text((consent.contentHtml ?? "").htmlToAttributedString())
                                    .font(.system(size: 14))
                                    .foregroundColor(NKColors.textSecondary(colorScheme))
                                    .lineSpacing(4)
                                    .padding(.top, 8)
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(AppStrings.t("KVKK metni"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchConsents()
        }
    }
    
    private func fetchConsents() async {
        do {
            let fetched = try await NetworkManager.shared.fetchConsents()
            await MainActor.run {
                self.consents = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = AppStrings.t("Sunucu hatası")
                self.isLoading = false
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppStrings.currentLocale
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }
}
