import SwiftUI

struct ModuleView: View {
    let task: JourneyStep
    @ObservedObject var viewModel: DashboardViewModel
    var clinicalState: PatientClinicalState? = nil
    var onComplete: (() -> Void)? = nil

    var body: some View {
        if shouldUseClinicalShell {
            ClinicalScreenRunner(initialState: clinicalState) {
                onComplete?()
                Task { await viewModel.reloadDashboard() }
            }
        } else {
            LegacyModuleView(task: task, viewModel: viewModel, onComplete: onComplete)
        }
    }

    private var shouldUseClinicalShell: Bool {
        clinicalState?.usesClinicalShell == true && viewModel.shouldUseClinicalRunner(for: task)
    }
}

private struct LegacyModuleView: View {
    @Environment(\.colorScheme) var colorScheme
    let task: JourneyStep
    @ObservedObject var viewModel: DashboardViewModel
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var contentAppeared = false
    @State private var selectedQuizOption: String?
    @State private var showQuestionnaire = false
    @State private var showCheckin = false
    @State private var isPdfFullScreen = false
    @State private var measurementValues: [String: String] = [:]

    private var typeUI: ModuleTypeUI {
        ModuleTypeUI.forType(task.module.moduleType)
    }

    /// Extract text from the module content
    private var contentText: String {
        let qTypes = ["question_answer", "questionnaire", "quiz"]
        if qTypes.contains(task.module.moduleType) {
            if case .dictionary(let dict) = task.module.content,
               let desc = dict["description"]?.stringValue, !desc.isEmpty {
                return desc
            }
            return "Lütfen bu test/anket modülünü doldurunuz."
        }
        if task.module.moduleType == "checkin" || task.module.moduleType == "daily_checkin" {
            return "Lütfen günlük takip formunu doldurunuz."
        }
        return task.module.content?.textValue ?? ""
    }

    var body: some View {
        NavigationView {
            ZStack {
                NKColors.bgPrimary(colorScheme).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        heroHeader
                        VStack(alignment: .leading, spacing: 24) {
                            dynamicContent
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .offset(y: contentAppeared ? 0 : 30)
                        .opacity(contentAppeared ? 1 : 0)
                        Spacer(minLength: 120)
                    }
                }

                VStack { Spacer(); bottomAction }

                if showSuccess { successOverlay }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NKColors.bgPrimary(colorScheme), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3)) {
                    contentAppeared = true
                }
            }
            .sheet(isPresented: $showQuestionnaire) {
                if let targetId = getQuestionnaireTargetId() {
                    QuestionnaireView(
                        questionnaireVersionId: targetId,
                        moduleTitle: task.module.title,
                        onComplete: {
                            showQuestionnaire = false
                            // QuestionnaireView already submitted the data.
                            // Don't call completeModule() — it fails for pseudo-tasks (conditional assignment).
                            // Just dismiss and reload.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                dismiss()
                                onComplete?()
                                Task { await viewModel.reloadDashboard() }
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showCheckin) {
                if let targetId = getCheckinTargetId() {
                    CheckinView(
                        checkinTemplateId: targetId,
                        moduleTitle: task.module.title,
                        onComplete: {
                            showCheckin = false
                            completeModule()
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $isPdfFullScreen) {
                if case .dictionary(let dict) = task.module.content,
                   let pdfUrl = (dict["fileUrl"]?.stringValue ?? dict["pdfUrl"]?.stringValue),
                   let url = URL(string: pdfUrl) {
                    NavigationView {
                        EmbeddedPDFView(url: url)
                            .edgesIgnoringSafeArea(.bottom)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: { isPdfFullScreen = false }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(NKColors.textSecondary(colorScheme))
                                    }
                                }
                            }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            Rectangle()
                .fill(typeUI.gradient)
                .frame(height: 220)
                .overlay(
                    // Pattern overlay
                    GeometryReader { geometry in
                        ZStack {
                            ForEach(0..<6, id: \.self) { i in
                                Circle()
                                    .fill(NKColors.glassBackground(colorScheme))
                                    .frame(width: CGFloat.random(in: 40...120))
                                    .offset(
                                        x: CGFloat.random(in: -50...geometry.size.width),
                                        y: CGFloat.random(in: -20...geometry.size.height)
                                    )
                            }
                        }
                    }
                )

            // Content
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: typeUI.icon)
                        .font(.system(size: 14, weight: .semibold))

                    Text(ModuleTypeUI.localizedName(task.module.moduleType).uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1.5)
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(NKColors.glassBackground(colorScheme))
                )

                Text(task.module.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let subtitle = task.module.subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Dynamic Content

    @ViewBuilder
    private var dynamicContent: some View {
        switch task.module.moduleType {
        case "article", "education_card", "html_content":
            articleContent
        case "video":
            videoContent
        case "quiz", "questionnaire", "question_answer":
            questionnairePromptContent
        case "checkin", "daily_checkin":
            checkinPromptContent
        case "exercise", "kegel_exercise":
            exerciseContent
        case "breathing", "breathing_exercise":
            breathingContent
        case "timer":
            timerContent
        case "file_pdf":
            pdfContent
        case "consent":
            consentContent
        case "risk", "risk_alert":
            riskAlertContent
        case "measurement", "measurement_input", "patient_measurements":
            measurementContent
        default:
            genericContent
        }
    }

    // MARK: - Article

    private var articleContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reading time estimate
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                Text(AppStrings.t("Tahmini okuma süresi: 3 dk"))
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(NKColors.textTertiary(colorScheme))

            Text(contentText.htmlToAttributedString())
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Video

    private var videoContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let videoUrl = task.module.content?.videoUrl, !videoUrl.isEmpty {
                VideoPlayerView(urlString: videoUrl)
            } else {
                // Fallback / Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(NKColors.bgCard(colorScheme))
                        .frame(height: 200)

                    ZStack {
                        Circle()
                            .fill(NKColors.glassBackground(colorScheme))
                            .frame(width: 70, height: 70)

                        Circle()
                            .fill(NKColors.glassBackground(colorScheme))
                            .frame(width: 56, height: 56)

                        Image(systemName: "video.slash")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
            }

            Text(contentText.htmlToAttributedString())
                .font(.system(size: 16))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .lineSpacing(6)
        }
    }

    // MARK: - Questionnaire Prompt

    private var questionnairePromptContent: some View {
        VStack(spacing: 20) {
            Text(contentText.htmlToAttributedString())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .lineSpacing(4)

            VStack(spacing: 16) {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 44))
                    .foregroundColor(typeUI.color)

                Text(AppStrings.t("Anketi doldurmak için aşağıdaki butona tıklayın"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(NKColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)

                Button(action: {
                    showQuestionnaire = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                        Text(AppStrings.t("Anketi Başlat"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(typeUI.gradient)
                    )
                }
            }
            .padding(20)
            .glassCard()
        }
    }

    // MARK: - Check-in Prompt

    private var checkinPromptContent: some View {
        VStack(spacing: 20) {
            Text(contentText.htmlToAttributedString())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .lineSpacing(4)

            VStack(spacing: 16) {
                Image(systemName: "heart.text.clipboard.fill")
                    .font(.system(size: 44))
                    .foregroundColor(NKColors.accentTeal)

                Text(AppStrings.t("Günlük durumunuzu kaydetmek için aşağıdaki butona tıklayın"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(NKColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)

                Button(action: {
                    showCheckin = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(AppStrings.t("Günlük Takibi Başlat"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(NKColors.tealGradient)
                    )
                }
            }
            .padding(20)
            .glassCard()
        }
    }

    // MARK: - Exercise

    private var exerciseContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Exercise illustration placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(NKColors.bgCard(colorScheme))
                    .frame(height: 180)

                VStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 50))
                        .foregroundColor(NKColors.accentTeal)

                    Text(AppStrings.t("Egzersizi başlatmak için hazır olun"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(NKColors.textSecondary(colorScheme))
                }
            }

            Text(contentText.htmlToAttributedString())
                .font(.system(size: 16))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .lineSpacing(6)
        }
    }

    // MARK: - Breathing

    private var breathingContent: some View {
        VStack(spacing: 32) {
            if case .dictionary(let dict) = task.module.content {
                let inhale = dict["inhaleDuration"]?.doubleValue ?? 4.0
                let hold = dict["holdDuration"]?.doubleValue ?? 0.0
                let exhale = dict["exhaleDuration"]?.doubleValue ?? 4.0
                let holdEmpty = dict["holdEmptyDuration"]?.doubleValue ?? 0.0

                BreathingCircle(inhaleDuration: inhale, holdDuration: hold, exhaleDuration: exhale, holdEmptyDuration: holdEmpty)
            } else {
                BreathingCircle(inhaleDuration: 4.0, holdDuration: 0.0, exhaleDuration: 4.0, holdEmptyDuration: 0.0)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(NKColors.textSecondary(colorScheme))
                    Text(AppStrings.t("TALİMATLAR"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(NKColors.textSecondary(colorScheme))
                }

                Text(contentText.htmlToAttributedString())
                    .font(.system(size: 15))
                    .foregroundColor(NKColors.textPrimary(colorScheme))
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(NKColors.bgCard(colorScheme))
                    .shadow(color: NKColors.cardShadow(colorScheme), radius: 10, y: 5)
            )
        }
        .padding(.vertical, 16)
    }

    // MARK: - Timer

    private var timerContent: some View {
        VStack(spacing: 20) {
            if case .dictionary(let dict) = task.module.content {
                let duration = dict["duration"]?.intValue ?? 180
                let label = dict["label"]?.stringValue ?? "Süre"
                let startText = dict["startText"]?.stringValue ?? "Çişim geldi, sayacı başlat"
                let endText = dict["endText"]?.stringValue ?? "Artık çişinizi yapabilirsiniz"
                
                InteractiveTimerView(
                    duration: duration,
                    label: label,
                    startText: startText,
                    endText: endText,
                    typeColor: typeUI.color
                )
            } else {
                genericContent
            }
        }
    }

    // MARK: - PDF

    private var pdfContent: some View {
        VStack(spacing: 16) {
            if case .dictionary(let dict) = task.module.content,
               let pdfUrl = (dict["fileUrl"]?.stringValue ?? dict["pdfUrl"]?.stringValue),
               let url = URL(string: pdfUrl) {
                VStack(spacing: 12) {
                    EmbeddedPDFView(url: url)
                        .frame(height: 450)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    Button(action: {
                        isPdfFullScreen = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                            Text(AppStrings.t("Tam Ekranda Oku"))
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(typeUI.gradient))
                    }
                }
            } else {
                genericContent
            }
        }
    }

    // MARK: - Consent

    private var consentContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if case .dictionary(let dict) = task.module.content,
               let html = dict["consentTextHtml"]?.stringValue {
                let plain = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                Text(plain)
                    .font(.system(size: 15))
                    .foregroundColor(NKColors.textPrimary(colorScheme))
                    .lineSpacing(5)
            } else {
                Text(contentText.htmlToAttributedString())
                    .font(.system(size: 15))
                    .foregroundColor(NKColors.textPrimary(colorScheme))
                    .lineSpacing(5)
            }
        }
    }

    // MARK: - Risk Alert

    private var riskAlertContent: some View {
        var alertMessage = "Risk tespit edildi."
        var safeMessage = "Değerleriniz normal."
        var missingMessage = "Lütfen önce ilgili anketi doldurunuz."
        var currentStatus: RiskStatus = .missing

        if case .dictionary(let dict) = task.module.content {
            if let aMsg = dict["alertMessage"]?.stringValue, !aMsg.isEmpty { alertMessage = aMsg }
            if let sMsg = dict["safeMessage"]?.stringValue, !sMsg.isEmpty { safeMessage = sMsg }
            if let mMsg = dict["missingMessage"]?.stringValue, !mMsg.isEmpty { missingMessage = mMsg }
            
            if let statusStr = dict["computedRiskStatus"]?.stringValue {
                switch statusStr {
                case "safe": currentStatus = .safe
                case "risk": currentStatus = .risk
                default: currentStatus = .missing
                }
            }
        }

        return RiskAlertContentView(
            alertMessage: alertMessage,
            safeMessage: safeMessage,
            missingMessage: missingMessage,
            status: currentStatus,
            onSolveTest: {
                showQuestionnaire = true
            }
        )
    }

    // MARK: - Generic

    private var measurementContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(AppStrings.t("Lütfen aşağıdaki ölçümleri giriniz:"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(NKColors.textSecondary(colorScheme))

            if let raw = task.module.content?.textValue,
               let data = raw.data(using: .utf8),
               let parsed = try? JSONDecoder().decode(MeasurementContentData.self, from: data),
               let metrics = parsed.metrics {

                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(metric.name) (\(metric.unit))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(NKColors.textPrimary(colorScheme))

                        if metric.type == "boolean" {
                            Toggle(AppStrings.t("Evet / Hayır"), isOn: Binding(
                                get: { measurementValues[metric.name] == "true" },
                                set: { measurementValues[metric.name] = $0 ? "true" : "false" }
                            ))
                            .tint(NKColors.accentTeal)
                            .foregroundColor(NKColors.textPrimary(colorScheme))
                        } else {
                            TextField(
                                AppStrings.t("Değer girin"),
                                text: Binding(
                                    get: { measurementValues[metric.name] ?? "" },
                                    set: { measurementValues[metric.name] = $0 }
                                )
                            )
                            .keyboardType(metric.type == "integer" ? .numberPad : .decimalPad)
                            .foregroundColor(NKColors.textPrimary(colorScheme))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(NKColors.bgCard(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(NKColors.bgCard(colorScheme))
                            .shadow(color: NKColors.cardShadow(colorScheme), radius: 6, y: 2)
                    )
                }
            } else {
                Text(AppStrings.t("Ölçüm ayarları bulunamadı."))
                    .foregroundColor(NKColors.textSecondary(colorScheme))
            }
        }
    }


    private var genericContent: some View {
        Text(contentText.htmlToAttributedString())
            .font(.system(size: 16))
            .foregroundColor(NKColors.textPrimary(colorScheme))
            .lineSpacing(6)
    }

    // MARK: - Bottom Action

    private var bottomAction: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [NKColors.bgPrimary(colorScheme).opacity(0), NKColors.bgPrimary(colorScheme)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)

            Button(action: {
                handleCompleteAction()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            task.isCompleted
                                ? LinearGradient(colors: [NKColors.success, NKColors.success], startPoint: .leading, endPoint: .trailing)
                                : typeUI.gradient
                        )
                        .frame(height: 56)
                        .shadow(color: typeUI.color.opacity(0.35), radius: 16, y: 8)

                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "checkmark")
                                .font(.system(size: 16, weight: .bold))

                            Text(task.isCompleted ? AppStrings.t("Tamamlandı") : completeButtonText)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .disabled(task.isCompleted || isSubmitting)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(NKColors.bgPrimary(colorScheme))
        }
    }

    private var completeButtonText: String {
        switch task.module.moduleType {
        case "quiz", "questionnaire", "question_answer":
            return "Anketi Aç"
        case "checkin", "daily_checkin":
            return "Günlük Takibi Başlat"
        case "measurement", "measurement_input", "patient_measurements":
            return "Ölçümleri Kaydet"
        default:
            return "Görevi Tamamla"
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()
            
            VStack(spacing: 36) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "34D399"), Color(hex: "059669")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: Color(hex: "34D399").opacity(0.4), radius: 24, x: 0, y: 12)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                
                VStack(spacing: 12) {
                    Text(AppStrings.t("Tebrikler!"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(NKColors.textPrimary(colorScheme))
                    
                    Text(AppStrings.t("Bu modülü başarıyla tamamladınız."))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(NKColors.textSecondary(colorScheme))
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    dismiss()
                    Task {
                        await viewModel.reloadDashboard()
                    }
                }) {
                    Text(AppStrings.t("Devam Et"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "34D399"), Color(hex: "059669")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color(hex: "34D399").opacity(0.4), radius: 10, y: 5)
                        )
                }
                .padding(.bottom, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(NKColors.bgCard(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            .shadow(color: NKColors.cardShadow(colorScheme), radius: 40, y: 20)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
        .transition(.opacity)
        .zIndex(100)
    }

    // MARK: - Actions

    private func handleCompleteAction() {
        switch task.module.moduleType {
        case "quiz", "questionnaire", "question_answer":
            showQuestionnaire = true
        case "checkin", "daily_checkin":
            showCheckin = true
        default:
            completeModule()
        }
    }

    private func completeModule() {
        withAnimation(.spring(response: 0.3)) {
            isSubmitting = true
        }

        guard let enrollmentId = viewModel.activeEnrollment?.id else { return }

        Task {
            let resultData: [String: Any]? = (task.module.moduleType == "measurement" || task.module.moduleType == "measurement_input" || task.module.moduleType == "patient_measurements") ? measurementValues : nil
            let success = await viewModel.completeModule(
                enrollmentId: enrollmentId,
                moduleVersionId: task.module.id,
                resultData: resultData
            )

            await MainActor.run {
                if success {
                    isSubmitting = false
                    
                    let qTypes = ["question_answer", "questionnaire", "quiz"]
                    let isQuestionnaire = qTypes.contains(task.module.moduleType)
                    
                    Task {
                        if isQuestionnaire {
                            // Sheet is already closed (closed 0.65s ago by onComplete callback).
                            // Just dismiss the parent fullScreenCover immediately.
                            await MainActor.run {
                                viewModel.markTaskCompleted(taskId: task.id)
                                dismiss()
                                onComplete?()
                            }
                            // Reload dashboard after navigation settles
                            try? await Task.sleep(nanoseconds: 400_000_000)
                            await viewModel.reloadDashboard()
                        } else {
                            await MainActor.run {
                                viewModel.markTaskCompleted(taskId: task.id)
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showSuccess = true
                                }
                            }
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            await MainActor.run { dismiss() }
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            await viewModel.reloadDashboard()
                        }
                    }
                } else {
                    isSubmitting = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func getQuestionnaireTargetId() -> UUID? {
        let qTypes = ["question_answer", "questionnaire", "quiz"]
        if qTypes.contains(task.module.moduleType),
           case .dictionary(let dict) = task.module.content {
            if let formIdStr = dict["formId"]?.stringValue,
               let formId = UUID(uuidString: formIdStr) {
                return formId
            }
            if let qIdStr = dict["questionnaireVersionId"]?.stringValue,
               let qId = UUID(uuidString: qIdStr) {
                return qId
            }
        }
        
        if (task.module.moduleType == "risk" || task.module.moduleType == "risk_alert"),
           case .dictionary(let dict) = task.module.content,
           let formIdStr = dict["computedTargetFormId"]?.stringValue,
           let targetFormId = UUID(uuidString: formIdStr) {
            return targetFormId
        }

        return task.module.moduleId
    }

    private func getCheckinTargetId() -> String? {
        if case .dictionary(let dict) = task.module.content,
           let templateIdStr = dict["checkinTemplateId"]?.stringValue {
            return templateIdStr
        }
        return task.module.moduleId?.uuidString
    }
}

// MARK: - Breathing Animation

struct BreathingCircle: View {
    @Environment(\.colorScheme) var colorScheme
    var inhaleDuration: Double
    var holdDuration: Double
    var exhaleDuration: Double
    var holdEmptyDuration: Double
    var totalCycles: Int = 4

    @State private var pulseScale: CGFloat = 0.8
    @State private var opacity: Double = 0.4
    @State private var textScale: CGFloat = 0.95
    @State private var breathText = AppStrings.t("Hazır Olun")
    
    @State private var isPlaying: Bool = false
    @State private var currentCycle: Int = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                // Glow blur
                Circle()
                    .fill(Color(hex: "06B6D4").opacity(opacity * 0.4))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseScale * 1.3)
                    .blur(radius: 20)

                // Outer pulse
                Circle()
                    .stroke(Color(hex: "06B6D4").opacity(opacity * 0.6), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseScale * 1.25)

                // Middle ring
                Circle()
                    .fill(Color(hex: "06B6D4").opacity(opacity * 0.3))
                    .frame(width: 130, height: 130)
                    .scaleEffect(pulseScale * 1.1)

                // Progress Ring Background (Brighter & On Top of blur)
                Circle()
                    .stroke(NKColors.glassBorder(colorScheme), lineWidth: 8)
                    .frame(width: 230, height: 230)

                // Progress Ring Active
                Circle()
                    .trim(from: 0.0, to: CGFloat(currentCycle) / CGFloat(totalCycles))
                    .stroke(Color(hex: "0891B2"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 230, height: 230)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: currentCycle)

                // Inner circle (Fixed size so text never escapes)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "0891B2"), Color(hex: "06B6D4")],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: "06B6D4").opacity(0.5), radius: 10, x: 0, y: 5)

                Text(breathText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .scaleEffect(textScale)
                    .frame(width: 120)
            }
            .frame(height: 240) // Container height for the ring

            // Play / Pause Action
            Button(action: {
                if isPlaying {
                    stopBreathingAnimation()
                } else {
                    if currentCycle >= totalCycles { currentCycle = 0 }
                    startBreathingAnimation()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: isPlaying ? "pause.fill" : (currentCycle >= totalCycles ? "arrow.counterclockwise" : "play.fill"))
                        .font(.system(size: 18, weight: .bold))
                    Text(isPlaying ? "Durdur" : (currentCycle >= totalCycles ? "Tekrar Başla" : "Egzersize Başla"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 200)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "0891B2"))
                        .shadow(color: Color(hex: "0891B2").opacity(0.4), radius: 8, y: 4)
                )
            }
        }
        .onDisappear {
            stopBreathingAnimation()
        }
    }

    private func stopBreathingAnimation() {
        isPlaying = false
        animationTask?.cancel()
        withAnimation(.easeInOut(duration: 0.5)) {
            pulseScale = 0.8
            opacity = 0.4
            textScale = 0.95
            if currentCycle >= totalCycles {
                breathText = AppStrings.t("Tamamlandı")
            } else {
                breathText = AppStrings.t("Hazır Olun")
            }
        }
    }

    private func startBreathingAnimation() {
        isPlaying = true
        animationTask?.cancel()
        animationTask = Task {
            // Give a short grace period
            await MainActor.run { breathText = AppStrings.t("Başlıyoruz...") }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            while !Task.isCancelled && currentCycle < totalCycles {
                // Inhale
                await MainActor.run {
                    breathText = AppStrings.t("Nefes Alın")
                    withAnimation(.easeInOut(duration: inhaleDuration)) {
                        pulseScale = 1.0
                        opacity = 0.8
                        textScale = 1.05
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(inhaleDuration * 1_000_000_000))
                if Task.isCancelled { break }
                
                // Hold
                if holdDuration > 0 {
                    await MainActor.run { breathText = AppStrings.t("Tutun") }
                    try? await Task.sleep(nanoseconds: UInt64(holdDuration * 1_000_000_000))
                    if Task.isCancelled { break }
                }
                
                // Exhale
                await MainActor.run {
                    breathText = AppStrings.t("Nefes Verin")
                    withAnimation(.easeInOut(duration: exhaleDuration)) {
                        pulseScale = 0.6
                        opacity = 0.3
                        textScale = 0.95
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(exhaleDuration * 1_000_000_000))
                if Task.isCancelled { break }
                
                // Hold Empty
                if holdEmptyDuration > 0 {
                    await MainActor.run { breathText = AppStrings.t("Tutun") }
                    try? await Task.sleep(nanoseconds: UInt64(holdEmptyDuration * 1_000_000_000))
                    if Task.isCancelled { break }
                }
                
                // Cycle Complete
                await MainActor.run {
                    currentCycle += 1
                }
            }
            
            // Finish
            if currentCycle >= totalCycles && !Task.isCancelled {
                await MainActor.run {
                    stopBreathingAnimation()
                }
            }
        }
    }
}

// MARK: - Interactive Timer View

struct InteractiveTimerView: View {
    @Environment(\.colorScheme) var colorScheme
    let duration: Int
    let label: String
    let startText: String
    let endText: String
    let typeColor: Color

    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var isFinished = false
    @State private var timerTask: Task<Void, Never>?

    init(duration: Int, label: String, startText: String, endText: String, typeColor: Color) {
        self.duration = duration
        self.label = label
        self.startText = startText
        self.endText = endText
        self.typeColor = typeColor
        self._timeRemaining = State(initialValue: duration)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(label)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(NKColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)

            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                    .frame(width: 220, height: 220)

                // Progress circle
                Circle()
                    .trim(from: 0.0, to: CGFloat(duration - timeRemaining) / CGFloat(duration))
                    .stroke(typeColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: timeRemaining)

                // Timer text
                VStack(spacing: 8) {
                    if isFinished {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(NKColors.success)
                            .transition(.scale)
                    } else {
                        Text(String(format: "%d:%02d", timeRemaining / 60, timeRemaining % 60))
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundColor(typeColor)
                    }
                }
            }
            .frame(height: 240)

            ZStack {
                if isFinished {
                    Text(endText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(NKColors.success)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: {
                        if isRunning {
                            stopTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(isRunning ? "Durdur" : startText)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isRunning ? NKColors.warning : typeColor)
                                .shadow(color: (isRunning ? NKColors.warning : typeColor).opacity(0.4), radius: 8, y: 4)
                        )
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }
            .frame(height: 56) // Sabit yükseklik ile kaymayı (shift) önler
            .animation(.easeInOut, value: isFinished)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard()
        .onDisappear {
            timerTask?.cancel()
        }
    }

    private func startTimer() {
        isRunning = true
        timerTask?.cancel()
        timerTask = Task {
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                await MainActor.run {
                    timeRemaining -= 1
                    if timeRemaining <= 0 {
                        isFinished = true
                        isRunning = false
                    }
                }
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timerTask?.cancel()
    }
}

enum RiskStatus {
    case safe
    case risk
    case missing
}

struct RiskAlertContentView: View {
    @Environment(\.colorScheme) var colorScheme
    let alertMessage: String
    let safeMessage: String
    let missingMessage: String
    let status: RiskStatus
    var onSolveTest: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            // Duruma Göre İçerik
            Group {
                switch status {
                case .safe:
                    cardView(
                        icon: "checkmark.shield.fill",
                        color: NKColors.success,
                        title: AppStrings.t("Her Şey Yolunda"),
                        message: safeMessage
                    )
                case .risk:
                    cardView(
                        icon: "exclamationmark.triangle.fill",
                        color: NKColors.danger,
                        title: AppStrings.t("Klinik Uyarı"),
                        message: alertMessage
                    )
                case .missing:
                    cardView(
                        icon: "lock.doc.fill",
                        color: NKColors.textSecondary(colorScheme),
                        title: AppStrings.t("Veri Bekleniyor"),
                        message: missingMessage,
                        showButton: true
                    )
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .padding(.top, 10)
    }

    private func cardView(icon: String, color: Color, title: String, message: String, showButton: Bool = false) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 88, height: 88)
                
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 64, height: 64)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 8, y: 4)
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(NKColors.textPrimary(colorScheme))
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(NKColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            
            if showButton {
                Button(action: {
                    onSolveTest?()
                }) {
                    Text(AppStrings.t("İlgili Anketi Çöz"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(NKColors.primaryGradient)
                        .cornerRadius(20)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(NKColors.bgCard(colorScheme).opacity(0.6))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                )
        )
        .shadow(color: NKColors.cardShadow(colorScheme), radius: 20, y: 10)
    }
}

extension String {
    func htmlToAttributedString() -> AttributedString {
        var markdown = self
        
        // Basic block elements
        markdown = markdown.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<p.*?>", with: "", options: .regularExpression)
        
        // Headers
        markdown = markdown.replacingOccurrences(of: "<h1.*?>", with: "\n# ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</h1>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<h2.*?>", with: "\n## ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</h2>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<h3.*?>", with: "\n### ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</h3>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<h4.*?>", with: "\n#### ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</h4>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<h5.*?>", with: "\n##### ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</h5>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<h6.*?>", with: "\n###### ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</h6>", with: "\n", options: .caseInsensitive)
        
        // Bold / Italic
        markdown = markdown.replacingOccurrences(of: "<b.*?>", with: "**", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</b>", with: "**", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<strong.*?>", with: "**", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</strong>", with: "**", options: .caseInsensitive)
        
        markdown = markdown.replacingOccurrences(of: "<i.*?>", with: "*", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</i>", with: "*", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<em.*?>", with: "*", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</em>", with: "*", options: .caseInsensitive)
        
        // Lists
        markdown = markdown.replacingOccurrences(of: "<ul>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "</ul>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<ol>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "</ol>", with: "\n", options: .caseInsensitive)
        markdown = markdown.replacingOccurrences(of: "<li.*?>", with: "- ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</li>", with: "\n", options: .caseInsensitive)
        
        // Strip remaining tags
        markdown = markdown.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode HTML Entities
        markdown = markdown.replacingOccurrences(of: "&nbsp;", with: " ")
        markdown = markdown.replacingOccurrences(of: "&amp;", with: "&")
        markdown = markdown.replacingOccurrences(of: "&lt;", with: "<")
        markdown = markdown.replacingOccurrences(of: "&gt;", with: ">")
        markdown = markdown.replacingOccurrences(of: "&quot;", with: "\"")
        markdown = markdown.replacingOccurrences(of: "&#39;", with: "'")
        
        // Clean up multiple newlines
        markdown = markdown.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        markdown = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            var attr = try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            // SwiftUI will naturally apply the foregroundColor and font modifiers
            return attr
        } catch {
            return AttributedString(markdown)
        }
    }
}

struct MeasurementMetric: Codable, Identifiable {
    let id: String
    let name: String
    let unit: String
    let type: String
}

struct MeasurementContentData: Codable {
    let metrics: [MeasurementMetric]?
}
