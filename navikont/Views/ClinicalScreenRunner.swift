import SwiftUI

struct ClinicalScreenRunner: View {
    let initialState: PatientClinicalState?
    var onStateChanged: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var state: PatientClinicalState?
    @State private var screens: [ClinicalScreen] = []
    @State private var completedContentIds: Set<String> = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var isCompleting = false
    @State private var errorMessage: String?

    private let service = ClinicalService()

    init(initialState: PatientClinicalState? = nil, onStateChanged: (() -> Void)? = nil) {
        self.initialState = initialState
        self.onStateChanged = onStateChanged
    }

    var body: some View {
        NavigationView {
            ZStack {
                NKColors.bgPrimary(colorScheme).ignoresSafeArea()
                if isLoading {
                    VStack(spacing: 16) {
                        GradientIconBadge(
                            icon: "cross.case.fill",
                            gradient: NKColors.tealGradient,
                            size: 58
                        )
                        ProgressView().tint(NKColors.accentTeal)
                        Text("Klinik program hazırlanıyor")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(NKColors.textSecondary(colorScheme))
                    }
                    .padding(28)
                    .glassCard()
                } else if screens.isEmpty {
                    emptyState
                } else {
                    screenBody
                }
            }
            .navigationTitle(state?.currentModule?.rawValue ?? "Klinik Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Label("Kapat", systemImage: "xmark.circle.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(NKColors.textPrimary(colorScheme))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    SafetyHelpRouter()
                }
            }
        }
        .navigationViewStyle(.stack)
        .task { await load() }
    }

    private var screenBody: some View {
        let screen = screens[currentIndex]
        return VStack(spacing: 0) {
            GeometryReader { proxy in
                let progress = CGFloat(currentIndex + 1) / CGFloat(max(screens.count, 1))
                ZStack(alignment: .leading) {
                    Capsule().fill(NKColors.glassBackground(colorScheme))
                    Capsule()
                        .fill(NKColors.tealGradient)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.top, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        GradientIconBadge(
                            icon: icon(for: screen.kind),
                            gradient: gradient(for: screen.kind),
                            size: 50
                        )
                        VStack(alignment: .leading, spacing: 5) {
                            Text(screen.title)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(NKColors.textPrimary(colorScheme))
                            if let subtitle = screen.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(NKColors.textSecondary(colorScheme))
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 18)

                    ClinicalAssetView(
                        screen: screen,
                        testModeEnabled: state?.testModeEnabled
                    ) {
                        if screen.kind == .teachBack {
                            completedContentIds.insert(screen.contentId)
                            onStateChanged?()
                            advanceOrClose()
                        } else {
                            completeCurrent()
                        }
                    }

                    if let errorMessage {
                        ClinicalInlineNotice(
                            message: errorMessage,
                            icon: "exclamationmark.triangle.fill",
                            color: NKColors.danger
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .padding(.bottom, 90)
            }

            if showsRunnerFooter(for: screen) {
                runnerFooter(screen)
            }
        }
    }

    private func runnerFooter(_ screen: ClinicalScreen) -> some View {
        VStack(spacing: 10) {
            if !usesEmbeddedCompletion {
                ClinicalPrimaryActionButton(
                    title: isCurrentCompleted ? nextTitle : "Tamamla ve devam et",
                    icon: isCurrentCompleted ? "arrow.right.circle.fill" : "checkmark.circle.fill",
                    isLoading: isCompleting
                ) {
                    if isCurrentCompleted {
                        advanceOrClose()
                    } else {
                        completeCurrent()
                    }
                }
            }
            HStack(spacing: 10) {
                if currentIndex > 0 {
                    ClinicalSecondaryActionButton(
                        title: "Geri",
                        icon: "chevron.left",
                        action: { move(to: currentIndex - 1) }
                    )
                }
                if !screen.isRequired {
                    ClinicalSecondaryActionButton(
                        title: "Bu adımı atla",
                        icon: "forward.fill",
                        action: { move(to: min(currentIndex + 1, screens.count - 1)) }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(NKColors.bgCard(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NKColors.glassBorder(colorScheme))
                .frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            GradientIconBadge(icon: "hourglass", gradient: NKColors.coolGradient, size: 58)
            Text("Yeni adım bekleniyor")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(NKColors.textPrimary(colorScheme))
            Text("Klinik ekibiniz bir sonraki ekranı açtığında burada görünecek.")
                .multilineTextAlignment(.center)
                .foregroundStyle(NKColors.textSecondary(colorScheme))
            if let errorMessage {
                ClinicalInlineNotice(
                    message: errorMessage,
                    icon: "exclamationmark.triangle.fill",
                    color: NKColors.warning
                )
            }
            ClinicalPrimaryActionButton(
                title: "Tekrar kontrol et",
                icon: "arrow.clockwise",
                action: { Task { await load() } }
            )
        }
        .padding(30)
        .glassCard()
        .padding(20)
    }

    private var isCurrentCompleted: Bool {
        guard !screens.isEmpty else { return false }
        return screens[currentIndex].isCompleted ||
            completedContentIds.contains(screens[currentIndex].contentId)
    }

    private var nextTitle: String {
        currentIndex == screens.count - 1 ? "Kapat" : "Sonraki"
    }

    private var usesEmbeddedCompletion: Bool {
        guard !screens.isEmpty else { return false }
        return [
            ClinicalScreenKind.bladderDiary,
            .plan,
            .teachBack,
            .urgencySimulation,
            .m5Hub
        ].contains(screens[currentIndex].kind)
    }

    private func showsRunnerFooter(for screen: ClinicalScreen) -> Bool {
        currentIndex > 0 || !screen.isRequired || !usesEmbeddedCompletion
    }

    private func icon(for kind: ClinicalScreenKind) -> String {
        switch kind {
        case .article: return "doc.richtext.fill"
        case .audio: return "waveform.circle.fill"
        case .video: return "play.circle.fill"
        case .bladderDiary: return "drop.circle.fill"
        case .plan: return "doc.text.fill"
        case .teachBack: return "checkmark.bubble.fill"
        case .urgencySimulation: return "figure.mind.and.body"
        case .m5Hub: return "figure.walk.motion"
        case .m6Review: return "stethoscope"
        case .m7Activation: return "checkmark.seal.fill"
        case .m8Closure: return "flag.checkered"
        case .unknown: return "cross.case.fill"
        }
    }

    private func gradient(for kind: ClinicalScreenKind) -> LinearGradient {
        switch kind {
        case .video, .m5Hub: return NKColors.warmGradient
        case .bladderDiary, .teachBack, .m6Review: return NKColors.coolGradient
        default: return NKColors.tealGradient
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchClinicalState()
            state = response.clinicalState
            if let enrollmentId = response.clinicalState.enrollmentId {
                ClinicalOfflineStore.shared.configure(enrollmentId: enrollmentId)
            }
            screens = response.resolvedScreens.isEmpty
                ? fallbackScreens(for: response.clinicalState.currentModule)
                : response.resolvedScreens
            completedContentIds = Set(screens.filter(\.isCompleted).map(\.contentId))
            restorePosition()
        } catch {
            state = initialState
            if let enrollmentId = initialState?.enrollmentId {
                ClinicalOfflineStore.shared.configure(enrollmentId: enrollmentId)
            }
            screens = initialState?.screens ?? fallbackScreens(for: initialState?.currentModule)
            completedContentIds = Set(screens.filter(\.isCompleted).map(\.contentId))
            restorePosition()
            errorMessage = screens.isEmpty ? error.localizedDescription : "Çevrimdışı içerik gösteriliyor."
        }
        isLoading = false
    }

    private func restorePosition() {
        guard !screens.isEmpty else {
            currentIndex = 0
            return
        }
        if let serverId = state?.currentScreenId,
           let serverIndex = screens.firstIndex(where: { $0.id == serverId }) {
            currentIndex = serverIndex
            return
        }
        if let savedId = UserDefaults.standard.string(forKey: resumeKey),
           let savedIndex = screens.firstIndex(where: { $0.contentId == savedId }) {
            currentIndex = savedIndex
            return
        }
        currentIndex = screens.firstIndex(where: {
            $0.isRequired && !$0.isCompleted
        }) ?? 0
    }

    private func completeCurrent() {
        guard !screens.isEmpty, !isCompleting else { return }
        let screen = screens[currentIndex]
        if isCurrentCompleted {
            advanceOrClose()
            return
        }
        isCompleting = true
        errorMessage = nil
        Task {
            do {
                _ = try await service.completeAsset(
                    contentId: screen.contentId,
                    payload: AssetCompletionPayload(
                        completionId: UUID(),
                        contentVersion: screen.contentVersion,
                        completedAt: Date(),
                        metadata: nil
                    )
                )
                completedContentIds.insert(screen.contentId)
                isCompleting = false
                onStateChanged?()
                advanceOrClose()
            } catch {
                isCompleting = false
                errorMessage = "Tamamlama sunucuya kaydedilemedi: \(error.localizedDescription)"
            }
        }
    }

    private func advanceOrClose() {
        if currentIndex < screens.count - 1 {
            move(to: currentIndex + 1)
        } else {
            UserDefaults.standard.removeObject(forKey: resumeKey)
            dismiss()
        }
    }

    private func move(to index: Int) {
        guard screens.indices.contains(index) else { return }
        currentIndex = index
        UserDefaults.standard.set(screens[index].contentId, forKey: resumeKey)
    }

    private var resumeKey: String {
        "clinical.resume.\(state?.enrollmentId?.uuidString ?? "current")"
    }

    private func fallbackScreens(for module: ClinicalModuleCode?) -> [ClinicalScreen] {
        guard let module, module != .unknown else { return [] }
        let kind: ClinicalScreenKind
        let title: String
        let body: String
        switch module {
        case .m1:
            kind = .article
            title = "Programı tanıyın"
            body = "Klinik ekibinizin yayınladığı eğitim içerikleri bu alanda gösterilir."
        case .m2:
            kind = .bladderDiary
            title = "Mesane günlüğü"
            body = ""
        case .m3:
            kind = .plan
            title = "Tedavi planım"
            body = ""
        case .m4:
            kind = .urgencySimulation
            title = "Güvenli uygulama simülasyonu"
            body = ""
        case .m5:
            kind = .m5Hub
            title = "Gerçek yaşam uygulamaları"
            body = ""
        case .m6:
            kind = .m6Review
            title = "Klinik değerlendirme"
            body = ""
        case .m7:
            kind = .m7Activation
            title = "Etkinleştirilen destekler"
            body = ""
        case .m8:
            kind = .m8Closure
            title = "Program kapanışı"
            body = ""
        case .unknown:
            return []
        }
        return [ClinicalScreen(
            contentId: module.rawValue,
            module: module,
            kind: kind,
            title: title,
            body: body,
            isRequired: false
        )]
    }
}

private struct ClinicalAssetView: View {
    let screen: ClinicalScreen
    let testModeEnabled: Bool?
    var onInteractiveComplete: (() -> Void)?

    @State private var plan: ClinicalPlan?
    @State private var m6: M6Payload?
    @State private var m7: M7Payload?
    @State private var m8: M8Payload?
    @State private var errorMessage: String?
    @State private var isAwaitingPlan = false
    @Environment(\.colorScheme) private var colorScheme
    private let service = ClinicalService()

    var body: some View {
        Group {
            switch screen.kind {
            case .audio:
                if let url = screen.mediaURL {
                    AudioPlayerView(url: url, transcript: screen.transcript)
                } else {
                    textContent
                }
            case .video:
                if let url = screen.mediaURL {
                    VideoPlayerView(urlString: url.absoluteString)
                } else {
                    textContent
                }
            case .bladderDiary:
                BladderDiaryHubView(testModeAvailable: testModeEnabled)
            case .plan:
                if let plan {
                    PlanCardView(plan: plan, onContinue: onInteractiveComplete)
                } else if isAwaitingPlan {
                    PlanPreparationView()
                } else {
                    loadingContent
                }
            case .teachBack:
                if let episode = screen.teachBack {
                    TeachBackView(episode: episode, onSubmitted: onInteractiveComplete)
                } else {
                    textContent
                }
            case .urgencySimulation:
                UrgencySimulationView(onComplete: onInteractiveComplete)
            case .m5Hub:
                M5HubView()
            case .m6Review:
                if let m6 { M6PatientView(payload: m6) } else { loadingContent }
            case .m7Activation:
                if let m7 { M7PatientView(payload: m7) } else { loadingContent }
            case .m8Closure:
                if let m8 { M8PatientView(payload: m8) } else { loadingContent }
            case .article, .unknown:
                textContent
            }
        }
        .task(id: screen.id) { await loadPayload() }
    }

    private var textContent: some View {
        Text((screen.body ?? "").htmlToAttributedString())
            .font(.system(.body, design: .rounded))
            .foregroundStyle(NKColors.textPrimary(colorScheme))
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassCard(cornerRadius: 18)
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                ClinicalInlineNotice(
                    message: errorMessage,
                    icon: "exclamationmark.triangle.fill",
                    color: NKColors.danger
                )
                ClinicalSecondaryActionButton(
                    title: "Tekrar dene",
                    icon: "arrow.clockwise",
                    action: { Task { await loadPayload() } }
                )
            } else {
                ProgressView().tint(NKColors.accentTeal)
                Text("Klinik bilgiler hazırlanıyor")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(NKColors.textSecondary(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(18)
        .glassCard(cornerRadius: 18)
    }

    private func loadPayload() async {
        errorMessage = nil
        isAwaitingPlan = false
        do {
            switch screen.kind {
            case .plan:
                plan = try await service.fetchCurrentPlan()
            case .m6Review:
                m6 = try await service.fetchM6()
            case .m7Activation:
                m7 = try await service.fetchM7()
            case .m8Closure:
                m8 = try await service.fetchM8()
            default:
                break
            }
        } catch {
            if screen.kind == .plan,
               case NetworkError.serverError(let status, _) = error,
               status == 404 {
                isAwaitingPlan = true
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}
