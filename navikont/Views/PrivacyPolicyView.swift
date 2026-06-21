import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    // UI Helpers
    private var primaryColor: Color { Color(hex: "06B6D4") } // Cyan theme
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gizlilik Politikası ve KVKK Aydınlatma Metni")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(NKColors.textPrimary)
                        
                        Text("Son Güncelleme: \(formattedDate())")
                            .font(.system(size: 13))
                            .foregroundColor(NKColors.textTertiary)
                    }
                    
                    policySection(title: "1. Veri Sorumlusunun Kimliği", content: """
                    Bu uygulama üzerinden toplanan kişisel verileriniz, "CERİLAS Yüksek Teknoloji Sanayi ve Ticaret AŞ" (VKN: 2061561435) veri sorumlusu sıfatıyla işlenmektedir. İletişim e-posta adresimiz: deniz@cerilas.com
                    """)
                    
                    policySection(title: "2. Kişisel Verilerin İşlenme Amacı", content: """
                    Toplanan kişisel sağlık verileriniz, kimlik ve iletişim bilgileriniz;
                    • Size özel tıbbi programların (görevler, check-inler, egzersizler) sunulması,
                    • Tedavi sürecinizin doktorunuz tarafından takibi ve iyileştirilmesi,
                    • Kullanıcı hesabınızın güvenliğinin sağlanması,
                    amacıyla 6698 sayılı Kişisel Verilerin Korunması Kanunu'na (KVKK) uygun olarak işlenmektedir.
                    """)
                    
                    policySection(title: "3. Verilerin Aktarılması", content: """
                    Kişisel verileriniz ve sağlık kayıtlarınız şifrelenmiş (encrypted) sunucularda yüksek güvenlik standartlarıyla korunmaktadır. Verileriniz, yasal zorunluluklar haricinde hiçbir şekilde üçüncü taraflara veya reklam şirketlerine satılmaz ve aktarılmaz. Yalnızca onay verdiğiniz tedavi ekibinizle (doktorlarınızla) paylaşılır.
                    """)
                    
                    policySection(title: "4. Veri Toplama Yöntemi ve Hukuki Sebebi", content: """
                    Verileriniz, uygulamanın içerisindeki check-in formları, anketler ve kendi isteğinizle sağladığınız ölçümler aracılığıyla elektronik ortamda toplanmaktadır. İşleme faaliyeti, "veri sahibinin açık rızası" ve "sağlık hizmetlerinin yürütülmesi" hukuki sebeplerine dayanmaktadır.
                    """)
                    
                    policySection(title: "5. İlgili Kişinin Hakları", content: """
                    KVKK'nın 11. maddesi uyarınca; kişisel verilerinizin işlenip işlenmediğini öğrenme, düzeltilmesini veya silinmesini talep etme haklarına sahipsiniz. Bu taleplerinizi doğrudan deniz@cerilas.com adresine e-posta göndererek bize iletebilirsiniz.
                    """)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("İletişim Bilgileri")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(NKColors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Şirket:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary) +
                            Text(" CERİLAS Yüksek Teknoloji Sanayi ve Ticaret AŞ")
                                .font(.system(size: 14))
                                .foregroundColor(NKColors.textSecondary)
                            
                            Text("VKN:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary) +
                            Text(" 2061561435")
                                .font(.system(size: 14))
                                .foregroundColor(NKColors.textSecondary)
                            
                            Text("E-posta:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary) +
                            Text(" deniz@cerilas.com")
                                .font(.system(size: 14))
                                .foregroundColor(NKColors.textSecondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    
                }
                .padding(20)
            }
        }
        .navigationTitle("Gizlilik Politikası")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NKColors.textPrimary)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(NKColors.textSecondary)
                .lineSpacing(4)
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: Date())
    }
}
