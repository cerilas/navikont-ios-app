import SwiftUI

// MARK: - NaviKont Design System (Adaptive)

struct NKColors {
    // These are resolved dynamically based on the current colorScheme
    // To keep backward compat, they default to dark if no env is available.
    
    // Primary palette (same in both modes)
    static let primaryGradientStart = Color(hex: "667EEA")
    static let primaryGradientEnd = Color(hex: "764BA2")
    
    // Accent palette (same in both modes)
    static let accentTeal = Color(hex: "2DD4BF")
    static let accentCyan = Color(hex: "22D3EE")
    static let accentAmber = Color(hex: "FBBF24")
    static let accentRose = Color(hex: "FB7185")
    
    // Semantic (same in both modes)
    static let success = Color(hex: "34D399")
    static let warning = Color(hex: "FBBF24")
    static let danger = Color(hex: "F87171")
    static let info = Color(hex: "60A5FA")
    
    // ── Adaptive Colors ──
    // Background
    static func bgPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "0F0F23") : Color(hex: "F5F6FA")
    }
    static func bgSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1A1A3E") : Color(hex: "ECEDF3")
    }
    static func bgCard(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1E1E42") : Color.white
    }
    static func bgCardLight(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "2A2A5E") : Color.white
    }
    
    // Text
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color(hex: "1A1A2E")
    }
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "A0A0C0") : Color(hex: "6B7280")
    }
    static func textTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "6B6B8D") : Color(hex: "9CA3AF")
    }
    
    // Glass/overlay
    static func glassBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    static func glassBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.12)
    }
    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.clear : Color.black.opacity(0.08)
    }

    // ── Legacy static accessors (dark mode defaults, for backward compat) ──
    static let bgPrimary = Color(hex: "0F0F23")
    static let bgSecondary = Color(hex: "1A1A3E")
    static let bgCard = Color(hex: "1E1E42")
    static let bgCardLight = Color(hex: "2A2A5E")
    
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0C0")
    static let textTertiary = Color(hex: "6B6B8D")
    
    // Gradients (same in both modes)
    static let primaryGradient = LinearGradient(
        colors: [primaryGradientStart, primaryGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let tealGradient = LinearGradient(
        colors: [accentTeal, accentCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "F97316"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let coolGradient = LinearGradient(
        colors: [Color(hex: "06B6D4"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func bgGradient(_ scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [bgPrimary(scheme), bgSecondary(scheme)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static let bgGradient = LinearGradient(
        colors: [bgPrimary, bgSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static func glassGradient(_ scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
            ? LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(
                colors: [Color.black.opacity(0.02), Color.black.opacity(0.01)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.12),
            Color.white.opacity(0.04)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(NKColors.glassGradient(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                    )
                    .shadow(color: NKColors.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Module Type Helpers

struct ModuleTypeUI {
    let icon: String
    let gradient: LinearGradient
    let color: Color
    
    static func forType(_ type: String) -> ModuleTypeUI {
        switch type {
        case "article", "html_content":
            return ModuleTypeUI(
                icon: "doc.richtext.fill",
                gradient: NKColors.coolGradient,
                color: Color(hex: "8B5CF6")
            )
        case "video":
            return ModuleTypeUI(
                icon: "play.circle.fill",
                gradient: NKColors.warmGradient,
                color: Color(hex: "F97316")
            )
        case "exercise", "kegel_exercise":
            return ModuleTypeUI(
                icon: "figure.run",
                gradient: NKColors.tealGradient,
                color: NKColors.accentTeal
            )
        case "breathing", "breathing_exercise":
            return ModuleTypeUI(
                icon: "wind",
                gradient: LinearGradient(
                    colors: [Color(hex: "06B6D4"), Color(hex: "0EA5E9")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "06B6D4")
            )
        case "quiz", "questionnaire", "question_answer":
            return ModuleTypeUI(
                icon: "list.clipboard.fill",
                gradient: LinearGradient(
                    colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "F59E0B")
            )
        case "checkin", "daily_checkin":
            return ModuleTypeUI(
                icon: "heart.text.clipboard.fill",
                gradient: NKColors.tealGradient,
                color: NKColors.accentTeal
            )
        case "timer":
            return ModuleTypeUI(
                icon: "timer",
                gradient: LinearGradient(
                    colors: [Color(hex: "7C3AED"), Color(hex: "A855F7")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "A855F7")
            )
        case "measurement", "measurement_input", "patient_measurements":
            return ModuleTypeUI(
                icon: "ruler.fill",
                gradient: LinearGradient(
                    colors: [Color(hex: "EC4899"), Color(hex: "BE185D")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "EC4899")
            )
        case "file_pdf":
            return ModuleTypeUI(
                icon: "doc.fill",
                gradient: LinearGradient(
                    colors: [Color(hex: "DC2626"), Color(hex: "F97316")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "DC2626")
            )
        case "consent":
            return ModuleTypeUI(
                icon: "signature",
                gradient: NKColors.primaryGradient,
                color: NKColors.primaryGradientStart
            )
        case "education_card":
            return ModuleTypeUI(
                icon: "lightbulb.fill",
                gradient: NKColors.primaryGradient,
                color: NKColors.primaryGradientStart
            )
        case "task":
            return ModuleTypeUI(
                icon: "checkmark.seal.fill",
                gradient: NKColors.tealGradient,
                color: NKColors.success
            )
        default:
            return ModuleTypeUI(
                icon: "square.grid.2x2.fill",
                gradient: NKColors.primaryGradient,
                color: NKColors.primaryGradientStart
            )
        }
    }

    static func localizedName(_ type: String) -> String {
        switch type {
        case "article", "html_content": return "Makale"
        case "video": return "Video"
        case "exercise", "kegel_exercise": return "Egzersiz"
        case "breathing", "breathing_exercise": return "Nefes Egzersizi"
        case "quiz", "questionnaire", "question_answer": return "Değerlendirme"
        case "checkin", "daily_checkin": return "Günlük Check-in"
        case "timer": return "Zamanlayıcı"
        case "measurement", "measurement_input", "patient_measurements": return "Ölçüm"
        case "file_pdf": return "PDF Rehber"
        case "consent": return "Onam"
        case "education_card": return "Bilgi Kartı"
        case "task": return "Görev"
        default: return "İçerik"
        }
    }
}

// MARK: - Animated Shimmer

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        (colorScheme == .dark ? Color.white : Color.black).opacity(0),
                        (colorScheme == .dark ? Color.white : Color.black).opacity(0.1),
                        (colorScheme == .dark ? Color.white : Color.black).opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: phase)
                .onAppear {
                    phase = 300
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

struct AppStrings {
    static let en: [String: String] = [
        "Egzersizi başlatmak için hazır olun": "Get ready to start the exercise",
        "TEST MODU AKTİF": "TEST MODE ACTIVE",
        "Başarılı": "Success",
        "Sahip Olunan Hastalıklar": "Existing Conditions",
        "Tamam": "OK",
        "Güvenlik Ayarları": "Security Settings",
        "Programa katılımınızdan itibaren ilerlemeniz": "Your progress since joining the program",
        "ornek@navikont.com": "example@navikont.com",
        " CERİLAS Yüksek Teknoloji Sanayi ve Ticaret AŞ": " CERILAS High Tech Industry and Trade Inc.",
        "Kan Grubu": "Blood Type",
        "Henüz hiç bildiriminiz yok.": "You have no notifications yet.",
        "Tam Ekranda Oku": "Read in Full Screen",
        "Ayrıca Bu Tarihte Çözülenler": "Also completed on this date",
        "Boy (cm)": "Height (cm)",
        "••••••••": "••••••••",
        "Sağlık ve Fiziksel Bilgiler": "Health and Physical Information",
        "Anketi doldurmak için aşağıdaki butona tıklayın": "Click the button below to fill out the survey",
        "Giriş Yap": "Login",
        "Size Nasıl Yardımcı Olabiliriz?": "How Can We Help You?",
        "Tebrikler!": "Congratulations!",
        "Bugünkü durumunuzu kaydedin": "Record your status for today",
        "İlgili Anketi Çöz": "Take the Related Survey",
        "Çıkış Yap": "Logout",
        "NaviKont Programı": "NaviKont Program",
        "Tahmini okuma süresi: 3 dk": "Estimated reading time: 3 min",
        "Ölçüm ayarları bulunamadı.": "Measurement settings not found.",
        "Dijital Sağlık Asistanınız": "Your Digital Health Assistant",
        "Geri": "Back",
        "Kilo (kg)": "Weight (kg)",
        "Cinsiyet": "Gender",
        " 2061561435": " 2061561435",
        "VKN:": "Tax ID:",
        "Devam Et": "Continue",
        "Cevaplarınız güvenle kaydedildi.": "Your answers have been safely recorded.",
        "Şirket:": "Company:",
        "Bu ayarlar telefonunuzun yerleşik hafızasında güvenle saklanmaktadır.": "These settings are securely stored on your phone's built-in memory.",
        "Zorunlu": "Required",
        "Bugün kendinizi nasıl hissediyorsunuz?": "How do you feel today?",
        "Yeni şifreler eşleşmiyor": "New passwords do not match",
        "Check-in Tamamla": "Complete Check-in",
        "Günü Tamamla": "Complete Day",
        "Doğum Tarihi": "Date of Birth",
        "Lütfen aşağıdaki ölçümleri giriniz:": "Please enter the following measurements:",
        "DiGA Sertifikalı Sağlık Uygulaması": "DiGA Certified Health App",
        "Hesap güvenliğiniz için şifrenizi güçlü ve benzersiz tutun.": "Keep your password strong and unique for account security.",
        "Bu modülü başarıyla tamamladınız.": "You have successfully completed this module.",
        "Görünüm": "Appearance",
        "Geliştirici test modunu açmak için şifreyi girin.": "Enter the password to open developer test mode.",
        "Bu güne atanmış bir görev bulunmuyor.": "There are no tasks assigned for this day.",
        "Tekrar Dene": "Try Again",
        "Görev Yok": "No Tasks",
        "Günlük durumunuzu kaydetmek için aşağıdaki butona tıklayın": "Click the button below to record your daily status",
        "Diğer Bildirimler": "Other Notifications",
        "Bilgi": "Info",
        "İnceleme Bekleniyor": "Pending Review",
        " deniz@cerilas.com": " deniz@cerilas.com",
        "NaviKont": "NaviKont",
        "NaviKont, Dijital Sağlık Asistanınız": "NaviKont, Your Digital Health Assistant",
        "Güvenli • Kişisel • Sizinle birlikte": "Secure • Personal • By your side",
        "E-posta:": "Email:",
        "Şifremi Unuttum": "Forgot Password",
        "Anket Tamamlandı": "Survey Completed",
        "Veri yüklenemedi.": "Data could not be loaded.",
        "NaviKont v1.0.0": "NaviKont v1.0.0",
        "Çok etkiliyor": "Affects a lot",
        "Hiç etkilemiyor": "Doesn't affect at all",
        "İletişim Bilgileri": "Contact Information",
        "Program Takvimi": "Program Calendar",
        "Check-in formu yükleniyor...": "Loading check-in form...",
        "Günlük verileriniz kaydedildi.": "Your daily data has been saved.",
        "•": "•",
        "Size daha iyi hizmet verebilmemiz için fiziksel özelliklerinizi güncel tutun.": "Keep your physical attributes up to date so we can serve you better.",
        "Bugünkü Görevler": "Today's Tasks",
        "Anket yükleniyor...": "Loading survey...",
        "Şifreyi Güncelle": "Update Password",
        "Geçersiz Video": "Invalid Video",
        "Destek Ekibiyle İletişime Geç": "Contact Support Team",
        "Anketi Başlat": "Start Survey",
        "Kaydet": "Save",
        "Check-in Tamamlandı!": "Check-in Completed!",
        "Günlük Takibi Başlat": "Start Daily Tracking",
        "Aradığınız cevabı bulamadınız mı?": "Couldn't find the answer you were looking for?",
        "Değerlendirmeniz Alındı": "Your Rating Received",
        "Şifre en az 6 karakter olmalıdır": "Password must be at least 6 characters",
        "Uygulama Bildirimleri": "App Notifications",
        "TALİMATLAR": "INSTRUCTIONS",
        "Verileriniz KVKK kapsamında korunmaktadır": "Your data is protected under KVKK",
        "0": "0",
        "Gizlilik Politikası ve KVKK Aydınlatma Metni": "Privacy Policy and KVKK Consent Text",
        "Oturumu Kapat": "Log Out",
        "Sıkça Sorulan Sorular (SSS)": "Frequently Asked Questions (FAQ)",
        "Yeni Şifre (Tekrar)": "New Password (Confirm)",
        "Bildirimleri sessiz al": "Mute notifications",
        "Görev ve egzersiz hatırlatmaları": "Task and exercise reminders",
        "KVKK metni": "KVKK Consent",
        "Sık sorulan sorular": "Frequently asked questions",
        "Eski Şifre": "Old Password",
        "5. İlgili Kişinin Hakları": "5. Rights of the Data Subject",
        "Her Şey Yolunda": "Everything is Fine",
        "Tamamlanan": "Completed",
        "Klinik Uyarı": "Clinical Warning",
        "Su İçme Hatırlatıcıları": "Water Reminders",
        "Açık": "On",
        "Günlük Hatırlatıcılar": "Daily Reminders",
        "Haftalık raporlar ve makaleler": "Weekly reports and articles",
        "Toplam Görev": "Total Tasks",
        "4. Veri Toplama Yöntemi ve Hukuki Sebebi": "4. Data Collection Method and Legal Reason",
        "Şifre ve Güvenlik": "Password & Security",
        "1. Veri Sorumlusunun Kimliği": "1. Identity of the Data Controller",
        "Şifre değiştir": "Change password",
        "Yardım Merkezi": "Help Center",
        "Bildirimler": "Notifications",
        "Program Günü": "Program Day",
        "Boy, kilo, kan grubu": "Height, weight, blood type",
        "Düzenli sıvı alımı takibi": "Regular fluid intake tracking",
        "E-posta Bültenleri": "Email Newsletters",
        "Sessiz Mod": "Silent Mode",
        "2. Kişisel Verilerin İşlenme Amacı": "2. Purpose of Processing Personal Data",
        "3. Verilerin Aktarılması": "3. Transfer of Data",
        "Yeni Şifre": "New Password",
        "Gizlilik Politikası": "Privacy Policy",
        "Veri Bekleniyor": "Pending Data",
        "Günaydın ": "Good morning ",
        "Tünaydın ": "Good afternoon ",
        "İyi akşamlar ": "Good evening ",
        "İyi geceler ": "Good night ",
        "Aydınlık": "Light",
        "Karanlık": "Dark",
        "Otomatik": "Auto",
        "Günaydın 👋": "Good morning 👋",
        "İyi günler 👋": "Good afternoon 👋",
        "İyi akşamlar 👋": "Good evening 👋",
        "İyi geceler 🌙": "Good night 🌙",
        "Tamamlandı": "Completed",
        "Eksik": "Missed",
        "Bugün": "Today",
        "G": "D",
        "Erkek": "Male",
        "Kadın": "Female",
        "Diğer": "Other",
        "Sistem": "System",
        "Hazır Olun": "Get Ready",
        "Başlıyoruz...": "Starting...",
        "Nefes Alın": "Inhale",
        "Tutun": "Hold",
        "Nefes Verin": "Exhale",
        "Dil": "Language",
        "Uygulama Dili": "App Language",
        "Programın": "Program",
        "Günü": "Day",
        "Günü görevleri çözüldü": "Day tasks completed",
        "Eksik / Yapılmadı": "Missed / Not Done",
        "Test Modu Aktivasyonu": "Test Mode Activation",
        "Lütfen önce ilgili anketi doldurunuz.": "Please fill out the related survey first.",
        "Take the Related Survey": "Take the Related Survey",
        "Everything is Fine": "Everything is Fine",
        "4. Sağlık verilerim ve kişisel bilgilerim güvende mi?": "4. Are my health data and personal information safe?",
        "Güncel sağlık durumunuzun doğruluğu açısından, gün içinde bir kez gönderdiğiniz (tamamladığınız) check-in verilerini tekrar değiştiremezsiniz. Bir sonraki gün yeni verilerinizi girebilirsiniz.": "For the accuracy of your current health status, you cannot change the check-in data you submitted (completed) once during the day. You can enter your new data the next day.",
        "Programınız İptal Edildi": "Your Program Has Been Canceled",
        "Programınız Donduruldu": "Your Program is Suspended",
        "Şu An Uygun Değilsiniz": "You Are Not Eligible Right Now",
        "Değerlendirme sonucunuz mevcut tedavi programlarımızın hiçbirine uymuyor. Lütfen doktorunuza başvurun; sizin için en uygun adımı birlikte belirleyecektir.": "Your assessment result does not match any of our current treatment programs. Please contact your doctor; they will determine the most suitable next step with you.",
        "Doktorunuz sizin için en uygun adımı belirleyecektir. Uygulamaya tekrar erişim sağlandığında bilgilendirileceksiniz.": "Your doctor will determine the most suitable next step for you. You will be notified when access to the app is restored.",
        "Tedavi programınız sonlandırılmıştır. Lütfen detaylı bilgi veya yeni bir planlama için klinik ekibinizle iletişime geçiniz.": "Your treatment program has been ended. Please contact your clinical team for details or a new plan.",
        "Programınıza şu an erişilemiyor. Detaylı bilgi veya destek için klinik ekibinizle iletişime geçebilirsiniz.": "Your program is currently inaccessible. Please contact your clinical team for details or support.",
        "Ana sayfada (Dashboard) bulunan 'Günün Görevleri' kartlarına tıklayarak size atanan günlük anket, ölçüm veya bilgilendirme modüllerine ulaşabilir ve kolayca tamamlayabilirsiniz.": "You can access and easily complete your daily surveys, measurements, or information modules assigned to you by clicking on the 'Today's Tasks' cards on the Dashboard.",
        "Sunucudan veri alınamadı": "Could not fetch data from server",
        "Çişim geldi, sayacı başlat": "I need to pee, start the timer",
        "Bilgileriniz başarıyla güncellendi.": "Your information has been successfully updated.",
        "Anketi Aç": "Open Survey",
        "Şifre Değiştir": "Change Password",
        "Ana Sayfa": "Home",
        "Navikont, tedavi sürecinizi kolaylaştıran, günlük sağlık durumunuzu ve görevlerinizi takip edip doktorunuzla senkronize olmanızı sağlayan akıllı bir hasta takip platformudur.": "Navikont is a smart patient tracking platform that simplifies your treatment process, tracks your daily health status and tasks, and synchronizes with your doctor.",
        "Evet, girdiğiniz check-in verileri ve anket sonuçları, sizin tedavinizi yakından takip edebilmesi için anlık olarak sadece yetkili doktorunuzun (veya tedavi ekibinizin) ekranına düşmektedir.": "Yes, the check-in data and survey results you enter are instantly displayed only on the screen of your authorized doctor (or treatment team) so they can closely monitor your treatment.",
        "Contact Information": "Contact Information",
        "Task and exercise reminders": "Task and exercise reminders",
        "Artık çişinizi yapabilirsiniz": "You can pee now",
        "Lütfen günlük takip formunu doldurunuz.": "Please fill out the daily tracking form.",
        "9. Uygulama neden aktif bir internet bağlantısı istiyor?": "9. Why does the app require an active internet connection?",
        "7. Bildirim ayarlarını nasıl değiştirebilirim?": "7. How can I change the notification settings?",
        "Giriş ekranında bulunan 'Şifremi Unuttum' bağlantısına tıklayarak e-posta adresinize bir şifre sıfırlama bağlantısı gönderebilirsiniz. Ayrıca profilinizdeki 'Şifre ve Güvenlik' sekmesinden mevcut şifrenizi dilediğiniz zaman değiştirebilirsiniz.": "You can send a password reset link to your email address by clicking the 'Forgot Password' link on the login screen. You can also change your current password at any time from the 'Password & Security' tab in your profile.",
        "Silent Mode": "Silent Mode",
        "Bilinmeyen bir hata oluştu": "An unknown error occurred",
        "Oturum süresi doldu. Lütfen tekrar giriş yapın.": "Session expired. Please log in again.",
        "8. Tamamladığım bir anketi sonradan değiştirebilir miyim?": "8. Can I change a completed survey later?",
        "Günlük Check-in": "Daily Check-in",
        "Evet / Hayır": "Yes / No",
        "Cevabınızı yazın...": "Type your answer...",
        "Tekrar Başla": "Start Over",
        "Şifreniz güncellendi.": "Your password has been updated.",
        "Aktive Et": "Activate",
        "Görevi Tamamla": "Complete Task",
        "Egzersize Başla": "Start Exercise",
        "Değerleriniz normal.": "Your values are normal.",
        "Sunucu hatası": "Server error",
        "Veri yüklenemedi": "Data could not be loaded",
        "Resim yüklenirken bir hata oluştu": "An error occurred while loading the image",
        "Anket yüklenemedi": "Survey could not be loaded",
        "Güncelleme sırasında bir hata oluştu": "An error occurred during update",
        "Bağlantı hatası": "Connection error",
        "Veri işleme hatası": "Data processing error",
        "Gönderilemedi": "Could not send",
        "Giriş başarısız": "Login failed",
        "Güncellenemedi": "Could not update",
        "Son Güncelleme:": "Last Update:",
        "Gün:": "Day:",
        "Gün": "Day",
        "Aktif": "Active",
        "Profil": "Profile",
        "gün": "days",
        "Kapat": "Close",
        "E-posta": "Email",
        "Şifre": "Password",
        "Giriş": "Login"
    ]
    
    static var currentLanguageCode: String {
        if let stored = UserDefaults.standard.string(forKey: "app_language"), stored != "system", !stored.isEmpty {
            return stored
        }
        return Locale.current.language.languageCode?.identifier ?? "tr"
    }

    static var currentLocale: Locale {
        let lang = currentLanguageCode
        if lang.starts(with: "en") {
            return Locale(identifier: "en_US")
        }
        return Locale(identifier: "tr_TR")
    }

    static func t(_ text: String) -> String {
        let lang = currentLanguageCode
        if lang.starts(with: "en") {
            return en[text] ?? text
        }
        return text
    }
}
