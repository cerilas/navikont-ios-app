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
                    ProgressView("Klinik program yükleniyor…")
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
                    Button("Kapat") { dismiss() }
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
            ProgressView(value: Double(currentIndex + 1), total: Double(screens.count))
                .tint(NKColors.accentTeal)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(screen.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        if let subtitle = screen.subtitle {
                            Text(subtitle).foregroundStyle(.secondary)
                        }
                    }

                    ClinicalAssetView(screen: screen) {
                        if screen.kind == .teachBack {
                            completedContentIds.insert(screen.contentId)
                            onStateChanged?()
                            advanceOrClose()
                        } else {
                            completeCurrent()
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
                .padding(.bottom, 90)
            }

            HStack(spacing: 12) {
                if currentIndex > 0 {
                    Button("Geri") { move(to: currentIndex - 1) }
                        .buttonStyle(.bordered)
                }
                if !screen.isRequired {
                    Button("Atla") { move(to: min(currentIndex + 1, screens.count - 1)) }
                        .buttonStyle(.bordered)
                }
                if !usesEmbeddedCompletion {
                    Button {
                        if isCurrentCompleted {
                            advanceOrClose()
                        } else {
                            completeCurrent()
                        }
                    } label: {
                        if isCompleting {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(isCurrentCompleted ? nextTitle : "Tamamla ve devam et")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCompleting)
                }
            }
            .padding(16)
            .background(.bar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 44))
                .foregroundStyle(NKColors.accentTeal)
            Text("Yeni adım bekleniyor").font(.title2.bold())
            Text("Klinik ekibiniz bir sonraki ekranı açtığında burada görünecek.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.orange)
            }
            Button("Tekrar dene") { Task { await load() } }
                .buttonStyle(.borderedProminent)
        }
        .padding(30)
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
            .teachBack,
            .urgencySimulation,
            .m5Hub
        ].contains(screens[currentIndex].kind)
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
    var onInteractiveComplete: (() -> Void)?

    @State private var plan: ClinicalPlan?
    @State private var m6: M6Payload?
    @State private var m7: M7Payload?
    @State private var m8: M8Payload?
    @State private var errorMessage: String?
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
                BladderDiaryHubView()
            case .plan:
                if let plan { PlanCardView(plan: plan) } else { loadingContent }
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
            .font(.body)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }

    private func loadPayload() async {
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
            errorMessage = error.localizedDescription
        }
    }
}
