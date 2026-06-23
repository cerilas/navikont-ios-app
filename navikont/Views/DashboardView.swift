import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DashboardViewModel()
    
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
    @State private var showProfile = false
    @State private var tasksAppeared = false
    
    @State private var showTestModeAlert = false
    @State private var testModePassword = ""
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var selectedTask: JourneyStep? = nil
    
    var body: some View {
        Group {
            if let enrollment = viewModel.activeEnrollment, enrollment.status == "paused" || enrollment.status == "cancelled" {
                StatusBlockedView(status: enrollment.status)
            } else {
                NavigationView {
                    ZStack {
                // Background
                NKColors.bgPrimary(colorScheme).ignoresSafeArea()
                
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Top Header
                        headerSection
                        
                        // Test Mode Banner
                        if authService.isTestModeEnabled {
                            testModeBanner
                        }
                        
                        if viewModel.isLoading {
                            loadingSection
                        } else if let errorMsg = viewModel.errorMessage {
                            // Error State
                            errorSection(message: errorMsg)
                        } else if let enrollment = viewModel.activeEnrollment {
                            if enrollment.currentDay > 0 && !isPendingReview {
                                // Stats Row
                                statsSection(enrollment: enrollment)
                                
                                // Progress Card
                                progressCard(enrollment: enrollment)
                            }
                            
                            // Today's Tasks (or Pending Review card)
                            tasksSection
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadDashboard()
                animateEntrance()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .fullScreenCover(item: $selectedTask) { task in
                ModuleView(task: task, viewModel: viewModel, onComplete: {
                    selectedTask = nil
                })
            }
        }
        .navigationViewStyle(.stack)
        .alert("Test Modu Aktivasyonu", isPresented: $showTestModeAlert) {
            SecureField("Şifre", text: $testModePassword)
            Button("İptal", role: .cancel) { }
            Button("Aktive Et") {
                if testModePassword == "2423" {
                    authService.isTestModeEnabled = true
                }
            }
        } message: {
            Text("Geliştirici test modunu açmak için şifreyi girin.")
        }
        }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(NKColors.textSecondary(colorScheme))
                    .onTapGesture(count: 5) {
                        if authService.isTestModeEnabled {
                            authService.isTestModeEnabled = false
                        } else {
                            testModePassword = ""
                            showTestModeAlert = true
                        }
                    }
                
                Text(authService.currentUser?.firstName ?? "Hasta")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(NKColors.textPrimary(colorScheme))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Notification bell
                NavigationLink(destination: NotificationsView()) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(NKColors.glassBackground(colorScheme))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(NKColors.textSecondary(colorScheme))
                            )
                        
                        // We could bind this to an unread count from the view model, 
                        // but for now we leave the red dot as a constant pulse dot 
                        // or link it to a state. I'll just keep the pulse dot as is.
                        PulseDot(color: NKColors.accentRose)
                            .offset(x: -2, y: 2)
                    }
                }
                
                // Profile / Logout
                Button(action: {
                    showProfile = true
                }) {
                    if let base64String = authService.currentUser?.profileImage,
                       let imageData = Data(base64Encoded: base64String),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .shadow(color: Color(hex: "06B6D4").opacity(0.3), radius: 5, x: 0, y: 3)
                    } else {
                        Circle()
                            .fill(NKColors.primaryGradient)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String((authService.currentUser?.firstName ?? "H").prefix(1)))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .offset(y: headerAppeared ? 0 : -20)
        .opacity(headerAppeared ? 1 : 0)
    }
    
    // MARK: - Stats
    
    private func statsSection(enrollment: Enrollment) -> some View {
        HStack(spacing: 0) {
            AnimatedCounter(
                value: enrollment.currentDay,
                label: "Program Günü",
                icon: "calendar",
                color: NKColors.primaryGradientStart
            )
            
            Rectangle()
                .fill(NKColors.glassBackground(colorScheme))
                .frame(width: 1, height: 50)
            
            AnimatedCounter(
                value: completedCount,
                label: "Tamamlanan",
                icon: "checkmark.circle.fill",
                color: NKColors.success
            )
            
            Rectangle()
                .fill(NKColors.glassBackground(colorScheme))
                .frame(width: 1, height: 50)
            
            AnimatedCounter(
                value: viewModel.todayTasks.count,
                label: "Toplam Görev",
                icon: "list.bullet",
                color: NKColors.accentAmber
            )
        }
        .padding(.vertical, 20)
        .glassCard()
        .padding(.horizontal, 20)
        .offset(y: cardsAppeared ? 0 : 30)
        .opacity(cardsAppeared ? 1 : 0)
    }
    
    // MARK: - Progress Card
    
    private func progressCard(enrollment: Enrollment) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 20) {
                CircularProgressView(
                    progress: Double(enrollment.progressPercent) / 100.0,
                    lineWidth: 8,
                    size: 80,
                    gradient: NKColors.tealGradient
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("NaviKont Programı")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(NKColors.textPrimary(colorScheme))
                    
                    Text("Gün \(enrollment.currentDay) • Aktif")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(NKColors.accentTeal)
                    
                    StreakBadge(count: viewModel.streakCount)
                }
                
                Spacer()
                
                NavigationLink(destination: JourneyCalendarView(viewModel: viewModel)) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 24))
                        .foregroundColor(NKColors.accentTeal)
                        .padding(10)
                        .background(NKColors.accentTeal.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(20)
        }
        .glassCard()
        .padding(.horizontal, 20)
        .offset(y: cardsAppeared ? 0 : 30)
        .opacity(cardsAppeared ? 1 : 0)
    }
    
    // MARK: - Loading
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(NKColors.glassBackground(colorScheme))
                    .frame(height: 80)
                    .shimmer()
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func errorSection(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(NKColors.textTertiary(colorScheme))
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(NKColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.loadDashboard()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Tekrar Dene")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(NKColors.primaryGradient)
                )
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }
    
    private var isPendingReview: Bool {
        viewModel.todayTasks.count == 1 &&
        viewModel.todayTasks.first?.module.title == "Değerlendirmeniz Alındı"
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isPendingReview {
                pendingReviewCard
            } else {
                HStack {
                    Text("Bugünkü Görevler")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(NKColors.textPrimary(colorScheme))
                    
                    Spacer()
                    
                    Text("\(completedCount)/\(viewModel.todayTasks.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(NKColors.textSecondary(colorScheme))
                }
                .padding(.horizontal, 20)
                
                ForEach(Array(viewModel.todayTasks.enumerated()), id: \.element.id) { index, task in
                    Button(action: { selectedTask = task }) {
                        TaskCard(task: task, index: index)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                
                if !viewModel.todayTasks.isEmpty {
                    Button(action: {
                        if let enrollment = viewModel.activeEnrollment {
                            viewModel.updateCurrentDay(to: (enrollment.currentDay ?? 1) + 1)
                        }
                    }) {
                        HStack {
                            Text("Günü Tamamla")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.allRequiredTasksCompleted ? NKColors.accentTeal : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: viewModel.allRequiredTasksCompleted ? NKColors.accentTeal.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!viewModel.allRequiredTasksCompleted)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
        .offset(y: tasksAppeared ? 0 : 40)
        .opacity(tasksAppeared ? 1 : 0)
    }
    
    // MARK: - Pending Review Card
    
    private var pendingReviewCard: some View {
        VStack(spacing: 0) {
            // Top accent bar
            LinearGradient(
                colors: [Color(hex: "06B6D4"), Color(hex: "8B5CF6")],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "06B6D4").opacity(0.15), Color(hex: "8B5CF6").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "06B6D4").opacity(0.25), Color(hex: "8B5CF6").opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "06B6D4"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 24)
            
            // Title
            Text("Değerlendirmeniz Alındı")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color(hex: "06B6D4").opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 40)
                .padding(.top, 16)
            
            // Description
            VStack(spacing: 12) {
                infoRow(
                    icon: "checkmark.seal.fill",
                    color: Color(hex: "10B981"),
                    text: "Anket sonuçlarınız başarıyla kaydedildi."
                )
                
                infoRow(
                    icon: "stethoscope",
                    color: Color(hex: "06B6D4"),
                    text: "Doktorunuz değerlendirmenizi inceliyor."
                )
                
                infoRow(
                    icon: "bell.badge.fill",
                    color: Color(hex: "8B5CF6"),
                    text: "Programınız belirlendiğinde bildirim alacaksınız."
                )
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            
            // Status badge
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "F59E0B"))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(Color(hex: "F59E0B").opacity(0.4))
                            .frame(width: 16, height: 16)
                            .opacity(0.6)
                    )
                
                Text("İnceleme Bekleniyor")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "F59E0B"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(hex: "F59E0B").opacity(0.1))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(hex: "F59E0B").opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(NKColors.bgCard(colorScheme).opacity(0.7))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(NKColors.glassBorder(colorScheme), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(NKColors.textSecondary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private var completedCount: Int {
        viewModel.todayTasks.filter { $0.isCompleted }.count
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın 👋"
        case 12..<17: return "İyi günler 👋"
        case 17..<22: return "İyi akşamlar 👋"
        default: return "İyi geceler 🌙"
        }
    }
    
    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            headerAppeared = true
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3)) {
            cardsAppeared = true
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            tasksAppeared = true
        }
    }
}

// MARK: - Task Card

struct TaskCard: View {
    @Environment(\.colorScheme) var colorScheme
    let task: JourneyStep
    let index: Int
    
    private var typeUI: ModuleTypeUI {
        ModuleTypeUI.forType(task.module.moduleType)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Module type icon
            GradientIconBadge(
                icon: typeUI.icon,
                gradient: task.isCompleted
                    ? LinearGradient(colors: [NKColors.success, NKColors.success], startPoint: .top, endPoint: .bottom)
                    : typeUI.gradient,
                size: 50
            )
            .overlay(
                Group {
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(NKColors.success))
                            .offset(x: 18, y: -18)
                    }
                }
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.module.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(task.isCompleted ? NKColors.textSecondary(colorScheme) : NKColors.textPrimary(colorScheme))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(ModuleTypeUI.localizedName(task.module.moduleType))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(typeUI.color.opacity(0.9))
                    
                    if task.module.required {
                        Text("•")
                            .foregroundColor(NKColors.textTertiary(colorScheme))
                        Text("Zorunlu")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(NKColors.accentRose)
                    }
                }
            }
            
            Spacer()
            
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(NKColors.success)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NKColors.textTertiary(colorScheme))
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension DashboardView {
    // MARK: - Test Mode Banner
    private var testModeBanner: some View {
        HStack {
            Text("TEST MODU AKTİF")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)
            
            Spacer()
            
            if let enrollment = viewModel.activeEnrollment {
                Stepper(value: Binding(
                    get: { enrollment.currentDay ?? 1 },
                    set: { newDay in 
                        viewModel.updateCurrentDay(to: newDay)
                    }
                ), in: 1...365) {
                    Text("Gün: \(enrollment.currentDay ?? 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.yellow)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// MARK: - Modern Pull to Refresh

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ModernRefreshIndicator: View {
    @Environment(\.colorScheme) var colorScheme
    let offset: CGFloat
    let isRefreshing: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Pulse glow when refreshing
            Circle()
                .fill(NKColors.accentTeal.opacity(0.15))
                .frame(width: 44, height: 44)
                .scaleEffect(isRefreshing ? 1.4 : 1.0)
                .animation(isRefreshing ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: isRefreshing)
            
            // Background circle
            Circle()
                .fill(NKColors.bgPrimary(colorScheme))
                .frame(width: 36, height: 36)
                .shadow(color: NKColors.accentTeal.opacity(0.3), radius: isRefreshing ? 8 : 2, x: 0, y: 2)
            
            // Ring
            Circle()
                .trim(from: 0, to: isRefreshing ? 0.8 : min(offset / 100, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [NKColors.accentTeal.opacity(0.4), NKColors.accentTeal]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(isRefreshing ? rotation : Double(offset * 2)))
                .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .easeOut(duration: 0.2), value: isRefreshing)
            
            // Center Dot
            Circle()
                .fill(NKColors.accentTeal)
                .frame(width: 6, height: 6)
                .scaleEffect(isRefreshing ? 0.5 : (offset > 50 ? 1 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: offset > 50)
        }
        .frame(height: 60)
        .opacity(min(offset / 40, 1.0)) // Fade in as pulled down
        .onAppear {
            if isRefreshing {
                rotation = 360
            }
        }
        .onChange(of: isRefreshing) { newValue in
            if newValue {
                rotation = 360
            } else {
                rotation = 0
            }
        }
    }
}

struct StatusBlockedView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthService
    let status: String
    
    var body: some View {
        ZStack {
            // Arka Plan
            Color.black.ignoresSafeArea()
            
            // Görsel / Grafik arkaplan
            Circle()
                .fill(status == "cancelled" ? Color.red.opacity(0.3) : Color.blue.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(y: -100)
            
            VStack(spacing: 30) {
                Spacer()
                
                // İkon
                ZStack {
                    Circle()
                        .fill(status == "cancelled" ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: status == "cancelled" ? "xmark.octagon.fill" : "pause.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(status == "cancelled" ? .red : .orange)
                }
                
                // Başlık
                Text(status == "cancelled" ? "Programınız İptal Edildi" : "Programınız Donduruldu")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Açıklama
                Text(status == "cancelled" 
                     ? "Tedavi programınız sonlandırılmıştır. Lütfen detaylı bilgi veya yeni bir planlama için klinik ekibinizle iletişime geçiniz." 
                     : "Programınıza şu an erişilemiyor. Detaylı bilgi veya destek için klinik ekibinizle iletişime geçebilirsiniz.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Çıkış Butonu
                Button(action: {
                    withAnimation {
                        authService.logout()
                    }
                }) {
                    Text("Oturumu Kapat")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(NKColors.glassBackground(colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}
