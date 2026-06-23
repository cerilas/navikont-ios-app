import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpCenterView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // 10 Common Questions & Answers
    private let faqs: [FAQItem] = [
        FAQItem(question: "1. Navikont uygulaması nedir ve ne işe yarar?",
                answer: "Navikont, tedavi sürecinizi kolaylaştıran, günlük sağlık durumunuzu ve görevlerinizi takip edip doktorunuzla senkronize olmanızı sağlayan akıllı bir hasta takip platformudur."),
        
        FAQItem(question: "2. Günlük check-in görevlerimi nasıl tamamlarım?",
                answer: "Ana sayfada (Dashboard) bulunan 'Günün Görevleri' kartlarına tıklayarak size atanan günlük anket, ölçüm veya bilgilendirme modüllerine ulaşabilir ve kolayca tamamlayabilirsiniz."),
        
        FAQItem(question: "3. Şifremi unutursam nasıl sıfırlayabilirim?",
                answer: "Giriş ekranında bulunan 'Şifremi Unuttum' bağlantısına tıklayarak e-posta adresinize bir şifre sıfırlama bağlantısı gönderebilirsiniz. Ayrıca profilinizdeki 'Şifre ve Güvenlik' sekmesinden mevcut şifrenizi dilediğiniz zaman değiştirebilirsiniz."),
        
        FAQItem(question: "4. Sağlık verilerim ve kişisel bilgilerim güvende mi?",
                answer: "Kesinlikle. Tüm verileriniz KVKK standartlarına uygun olarak uçtan uca şifrelenmiş sunucularda saklanmaktadır. Bilgileriniz hiçbir kurum veya üçüncü şahısla paylaşılmaz."),
        
        FAQItem(question: "5. Günlük seri (streak) nedir?",
                answer: "Seri (Streak), görevlerinizi ara vermeden üst üste kaç gün boyunca tamamladığınızı gösteren bir motivasyon aracıdır. Her gün check-in yaptığınızda seri puanınız artar."),
        
        FAQItem(question: "6. Doktorum buraya girdiğim bilgileri görebiliyor mu?",
                answer: "Evet, girdiğiniz check-in verileri ve anket sonuçları, sizin tedavinizi yakından takip edebilmesi için anlık olarak sadece yetkili doktorunuzun (veya tedavi ekibinizin) ekranına düşmektedir."),
        
        FAQItem(question: "7. Bildirim ayarlarını nasıl değiştirebilirim?",
                answer: "Profil sayfanıza giderek 'Bildirimler' menüsüne tıklayabilir; günlük hatırlatıcıları, su içme uyarılarını veya e-posta bültenlerini dilediğiniz gibi açıp kapatabilirsiniz."),
        
        FAQItem(question: "8. Tamamladığım bir anketi sonradan değiştirebilir miyim?",
                answer: "Güncel sağlık durumunuzun doğruluğu açısından, gün içinde bir kez gönderdiğiniz (tamamladığınız) check-in verilerini tekrar değiştiremezsiniz. Bir sonraki gün yeni verilerinizi girebilirsiniz."),
        
        FAQItem(question: "9. Uygulama neden aktif bir internet bağlantısı istiyor?",
                answer: "Verilerinizin doktorunuzla anında senkronize edilebilmesi, anketlerin güvenle kaydedilmesi ve yeni günlük modüllerinizin (makale vb.) yüklenebilmesi için internet bağlantısı gerekmektedir."),
        
        FAQItem(question: "10. Teknik bir sorun yaşarsam kime ulaşmalıyım?",
                answer: "Uygulamayla ilgili herhangi bir donma, hata veya teknik problem yaşarsanız deniz@cerilas.com adresine e-posta göndererek doğrudan teknik destek ekibimizden yardım alabilirsiniz.")
    ]
    
    // UI Helpers
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
                        
                        Text("Size Nasıl Yardımcı Olabiliriz?")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(NKColors.textPrimary(colorScheme))
                        
                        Text("Sıkça Sorulan Sorular (SSS)")
                            .font(.system(size: 14))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // FAQ List
                    VStack(spacing: 16) {
                        ForEach(faqs) { faq in
                            FAQRow(faq: faq)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Contact Support Button
                    VStack(spacing: 12) {
                        Text("Aradığınız cevabı bulamadınız mı?")
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
                                Text("Destek Ekibiyle İletişime Geç")
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
        .navigationTitle("Yardım Merkezi")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQRow: View {
    @Environment(\.colorScheme) var colorScheme
    let faq: FAQItem
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
