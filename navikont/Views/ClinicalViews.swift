import SwiftUI
import AVKit

enum ClinicalHelpRoute: String, Identifiable {
    case technical
    case clinical
    case emergency

    var id: String { rawValue }
}

struct ClinicalPrimaryActionButton: View {
    let title: String
    let icon: String
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(NKColors.tealGradient.opacity(isDisabled ? 0.45 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

struct ClinicalSecondaryActionButton: View {
    let title: String
    let icon: String
    var isDisabled = false
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundStyle(NKColors.textPrimary(colorScheme))
                .background(
                    NKColors.glassBackground(colorScheme),
                    in: RoundedRectangle(cornerRadius: 15)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

struct ClinicalTextEntry: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var multiline = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
            }
            TextField(placeholder, text: $text, axis: multiline ? .vertical : .horizontal)
                .lineLimit(multiline ? 3...6 : 1...1)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(NKColors.textPrimary(colorScheme))
                .tint(NKColors.accentTeal)
                .padding(.horizontal, 14)
                .padding(.vertical, multiline ? 14 : 12)
                .background(
                    NKColors.glassBackground(colorScheme),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                )
        }
    }
}

struct ClinicalInlineNotice: View {
    let message: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            Text(message)
                .font(.caption)
                .foregroundStyle(NKColors.textSecondary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
    }
}

struct SafetyHelpRouter: View {
    @Environment(\.openURL) private var openURL
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Yardım", systemImage: "lifepreserver.fill")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(NKColors.accentTeal)
        }
        .confirmationDialog("Nasıl yardım alabilirsiniz?", isPresented: $isPresented) {
            Button("Teknik destek") { open("mailto:destek@navikont.com") }
            Button("Klinik ekibe ulaş") { open("mailto:klinik@navikont.com") }
            Button("Acil yardım (112)", role: .destructive) { open("tel://112") }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Acil belirtilerde uygulama içi mesaj beklemeyin; 112'yi arayın.")
        }
    }

    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        openURL(url)
    }
}

struct AudioPlayerView: View {
    let url: URL
    let transcript: String?

    @State private var player: AVPlayer
    @State private var isPlaying = false
    @State private var showsTranscript = false
    @Environment(\.colorScheme) private var colorScheme

    init(url: URL, transcript: String? = nil) {
        self.url = url
        self.transcript = transcript
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 18) {
                Button {
                    isPlaying.toggle()
                    isPlaying ? player.play() : player.pause()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(NKColors.accentTeal)
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sesli içerik")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(NKColors.textPrimary(colorScheme))
                    Text(isPlaying ? "Oynatılıyor" : "Dinlemeye hazır")
                        .font(.caption)
                        .foregroundStyle(NKColors.textSecondary(colorScheme))
                }
                Spacer()
            }

            if let transcript, !transcript.isEmpty {
                ClinicalSecondaryActionButton(
                    title: showsTranscript ? "Transkripti gizle" : "Transkripti göster",
                    icon: "captions.bubble.fill",
                    action: { withAnimation { showsTranscript.toggle() } }
                )
                if showsTranscript {
                    Text(transcript)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundStyle(NKColors.textPrimary(colorScheme))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            NKColors.glassBackground(colorScheme),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
            }
        }
        .padding(18)
        .glassCard()
        .onDisappear { player.pause() }
    }
}

struct PlanCardView: View {
    let plan: ClinicalPlan
    var onContinue: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Yayınlanmış tedavi planınız", systemImage: "doc.text.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(NKColors.accentTeal)
            Text(plan.title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(NKColors.textPrimary(colorScheme))
            if let summary = plan.summary {
                Text(summary).foregroundStyle(NKColors.textSecondary(colorScheme))
            }
            if let goals = plan.goals, !goals.isEmpty {
                clinicalList(title: "Hedefler", values: goals)
            }
            if let instructions = plan.instructions, !instructions.isEmpty {
                clinicalList(title: "Uygulama", values: instructions)
            }
            if let version = plan.versionNumber {
                Text("Plan sürümü \(version)")
                    .font(.caption)
                    .foregroundStyle(NKColors.textTertiary(colorScheme))
            }
            if let onContinue {
                ClinicalPrimaryActionButton(
                    title: "Planı okudum, devam et",
                    icon: "checkmark.circle.fill",
                    action: onContinue
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func clinicalList(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(NKColors.textPrimary(colorScheme))
            ForEach(values, id: \.self) { value in
                Label(value, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(NKColors.textPrimary(colorScheme), NKColors.accentTeal)
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        NKColors.glassBackground(colorScheme),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
        }
    }
}

struct PlanPreparationView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            GradientIconBadge(
                icon: "stethoscope.circle.fill",
                gradient: NKColors.coolGradient,
                size: 58
            )
            VStack(spacing: 7) {
                Text("Doktorunuz planınızı hazırlıyor")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                    .multilineTextAlignment(.center)
                Text("Mesane günlüğünüz incelendi. Size özel tedavi planı yayınlandığında bu sayfada görüntülenecek.")
                    .font(.subheadline)
                    .foregroundStyle(NKColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            Label("Plan hazır olduğunda uygulamada görebileceksiniz", systemImage: "bell.badge.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NKColors.accentTeal)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(
                    NKColors.accentTeal.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 28)
        .glassCard(cornerRadius: 20)
    }
}

struct TeachBackView: View {
    let episode: TeachBackEpisode
    var onSubmitted: (() -> Void)?

    @State private var answers: [String: String] = [:]
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    private let service = ClinicalService()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                GradientIconBadge(
                    icon: "checkmark.bubble.fill",
                    gradient: NKColors.coolGradient,
                    size: 52
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.title ?? "Planınızı birlikte kontrol edelim")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(NKColors.textPrimary(colorScheme))
                    Text("Sınav değil; planın size açık olduğundan emin olmak için kısa bir kontrol.")
                        .font(.subheadline)
                        .foregroundStyle(NKColors.textSecondary(colorScheme))
                }
            }
            .padding(18)
            .glassCard(cornerRadius: 18)

            ForEach(Array(episode.prompts.enumerated()), id: \.element.id) { index, prompt in
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 11) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(NKColors.tealGradient, in: Circle())
                        Text(prompt.question)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(NKColors.textPrimary(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let options = prompt.options, !options.isEmpty {
                        VStack(spacing: 9) {
                            ForEach(options, id: \.self) { option in
                                choiceButton(
                                    option,
                                    selected: answers[prompt.id] == option
                                ) {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        answers[prompt.id] = option
                                    }
                                }
                            }
                        }
                    } else {
                        ClinicalTextEntry(
                            title: nil,
                            placeholder: "Kendi sözlerinizle yazın",
                            text: binding(for: prompt.id),
                            multiline: true
                        )
                    }
                }
                .padding(18)
                .glassCard(cornerRadius: 18)
            }

            if let errorMessage {
                ClinicalInlineNotice(
                    message: errorMessage,
                    icon: "exclamationmark.triangle.fill",
                    color: NKColors.danger
                )
            }
            ClinicalPrimaryActionButton(
                title: "Yanıtları güvenle gönder",
                icon: "paperplane.fill",
                isLoading: isSubmitting,
                isDisabled: requiredAnswersMissing,
                action: submit
            )
        }
    }

    private func choiceButton(
        _ title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? NKColors.accentTeal : NKColors.textTertiary(colorScheme))
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                selected ? NKColors.accentTeal.opacity(0.12) : NKColors.glassBackground(colorScheme),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        selected ? NKColors.accentTeal : NKColors.glassBorder(colorScheme),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var requiredAnswersMissing: Bool {
        episode.prompts.contains { ($0.required ?? true) && (answers[$0.id] ?? "").isEmpty }
    }

    private func binding(for id: String) -> Binding<String> {
        Binding(get: { answers[id] ?? "" }, set: { answers[id] = $0 })
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                _ = try await service.submitTeachBack(TeachBackResponsePayload(
                    responseId: UUID(),
                    episodeId: episode.id,
                    answers: answers,
                    submittedAt: Date()
                ))
                isSubmitting = false
                onSubmitted?()
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct UrgencySimulationView: View {
    var onComplete: (() -> Void)?
    @State private var step = 0
    @Environment(\.colorScheme) private var colorScheme

    private let steps = [
        "Güvenli ve rahat bir yerde durun. İdrarınızı belirli bir süre tutma hedefi koymayın.",
        "Omuzlarınızı gevşetin ve sakin, doğal nefes alın.",
        "Size öğretilen baskılama tekniğini yalnız rahat olduğunuz ölçüde uygulayın.",
        "İhtiyaç azaldığında veya kendinizi hazır hissettiğinizde tuvalete sakin biçimde ilerleyin."
    ]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 13) {
                GradientIconBadge(
                    icon: "figure.mind.and.body",
                    gradient: NKColors.tealGradient,
                    size: 62
                )
                Text("Sıkışma simülasyonu")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                Text("Adım \(step + 1) / \(steps.count)")
                    .font(.caption.bold())
                    .foregroundStyle(NKColors.accentTeal)
                ProgressView(value: Double(step + 1), total: Double(steps.count))
                    .tint(NKColors.accentTeal)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .glassCard()

            Text(steps[step])
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(NKColors.textPrimary(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, minHeight: 130)
                .padding(20)
                .glassCard()

            ClinicalInlineNotice(
                message: "Geri sayım yoktur. Ağrı, kanama veya alışılmadık belirti olursa durun ve klinik yardım alın.",
                icon: "cross.case.fill",
                color: NKColors.warning
            )

            ClinicalPrimaryActionButton(
                title: step == steps.count - 1 ? "Simülasyonu tamamla" : "Hazırım, devam et",
                icon: step == steps.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill"
            ) {
                if step == steps.count - 1 {
                    onComplete?()
                } else {
                    withAnimation { step += 1 }
                }
            }
        }
    }
}

private struct LegacyBladderDiaryHubView: View {
    @StateObject private var store = ClinicalOfflineStore.shared
    @State private var session: BladderDiarySession?
    @State private var selectedType: BladderDiaryEventType = .void
    @State private var amount = ""
    @State private var urgency = 3
    @State private var measured = true
    @State private var retrospective = false
    @State private var note = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let service = ClinicalService()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading) {
                    Text("72 saatlik mesane günlüğü").font(.title2.bold())
                    Text(session == nil ? "Oturum başlatılmadı" : "Olaylar cihazda güvenle saklanır")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if store.isSyncing { ProgressView() }
            }

            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if session == nil {
                Button("Günlüğü başlat") { startSession() }
                    .buttonStyle(.borderedProminent)
            } else {
                entryForm
                eventList
                if canSubmitDiary {
                    Button("Günlüğü klinik incelemeye gönder") {
                        submitDiary()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.orange)
            }
        }
        .task { await load() }
    }

    private var entryForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Olay", selection: $selectedType) {
                Text("İşeme").tag(BladderDiaryEventType.void)
                Text("Sıvı alımı").tag(BladderDiaryEventType.fluid)
                Text("Kaçırma").tag(BladderDiaryEventType.leakage)
                Text("Uyku başlangıcı").tag(BladderDiaryEventType.sleepStart)
                Text("Uyku bitişi").tag(BladderDiaryEventType.sleepEnd)
            }
            .pickerStyle(.menu)

            if selectedType == .void || selectedType == .fluid {
                TextField("Miktar (ml)", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Toggle("Ölçebildim", isOn: $measured)
            }
            if selectedType == .void || selectedType == .leakage {
                Stepper("Sıkışma düzeyi: \(urgency)/4", value: $urgency, in: 0...4)
            }
            Toggle("Daha önce gerçekleşti", isOn: $retrospective)
            TextField("Not (isteğe bağlı)", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Button {
                saveEvent()
            } label: {
                Label("Olayı kaydet", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .glassCard()
    }

    private var eventList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kayıtlar").font(.headline)
            ForEach(store.diaryEvents) { event in
                HStack {
                    Image(systemName: icon(for: event.type))
                    VStack(alignment: .leading) {
                        Text(label(for: event.type)).font(.subheadline.bold())
                        Text(event.occurredAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(event.storageState == .serverStored ? "Sunucuda" : "Cihazda")
                        .font(.caption2.bold())
                        .foregroundStyle(event.storageState == .serverStored ? .green : .orange)
                }
                .padding(12)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func load() async {
        do {
            let current = try await service.fetchCurrentDiarySession()
            if let current {
                session = current
                store.activateDiarySession(current.id)
                store.mergeServerEvents(current.events ?? [])
            }
        } catch {
            errorMessage = "Sunucuya ulaşılamadı. Cihazdaki kayıtlar gösteriliyor."
        }
        isLoading = false
        await store.sync()
    }

    private func startSession() {
        isLoading = true
        Task {
            do {
                session = try await service.startDiarySession()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func saveEvent() {
        let event = BladderDiaryEvent(
            sessionId: session?.id,
            type: selectedType,
            amountMl: Double(amount),
            urgency: (selectedType == .void || selectedType == .leakage) ? urgency : nil,
            measured: measured,
            retrospective: retrospective,
            note: note.isEmpty ? nil : note
        )
        store.addDiaryEvent(event)
        amount = ""
        note = ""
        Task { await store.sync() }
    }

    private var canSubmitDiary: Bool {
        guard let session, let endsAt = session.endsAt else { return false }
        return Date() >= endsAt &&
            !store.diaryEvents.isEmpty &&
            !["submitted", "under_review", "reviewed", "approved"].contains(session.status)
    }

    private func submitDiary() {
        guard let session else { return }
        isLoading = true
        Task {
            await store.sync()
            do {
                self.session = try await service.submitDiary(sessionId: session.id)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func label(for type: BladderDiaryEventType) -> String {
        switch type {
        case .void: return "İşeme"
        case .fluid: return "Sıvı"
        case .leakage: return "Kaçırma"
        case .sleepStart: return "Uyku başlangıcı"
        case .sleepEnd: return "Uyku bitişi"
        }
    }

    private func icon(for type: BladderDiaryEventType) -> String {
        switch type {
        case .void: return "drop.fill"
        case .fluid: return "cup.and.saucer.fill"
        case .leakage: return "exclamationmark.circle.fill"
        case .sleepStart: return "moon.fill"
        case .sleepEnd: return "sun.max.fill"
        }
    }
}

struct M5HubView: View {
    @StateObject private var store = ClinicalOfflineStore.shared
    @State private var recordType: M5RecordType = .naturalUrgencyEvent
    @State private var urgency = 3
    @State private var outcome = ""
    @State private var notes = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Deneyiminizi kısa ve anlaşılır biçimde kaydedin.")
                    .font(.subheadline)
                    .foregroundStyle(NKColors.textSecondary(colorScheme))
                Text("Kayıt türü")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                HStack(spacing: 10) {
                    recordTypeButton(
                        title: "Sıkışma olayı",
                        icon: "exclamationmark.circle.fill",
                        type: .naturalUrgencyEvent
                    )
                    recordTypeButton(
                        title: "Uygulama özeti",
                        icon: "doc.text.fill",
                        type: .applicationSummary
                    )
                }

                if recordType == .naturalUrgencyEvent {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sıkışma düzeyi")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        HStack(spacing: 8) {
                            ForEach(0...4, id: \.self) { value in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) { urgency = value }
                                } label: {
                                    Text("\(value)")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .foregroundStyle(urgency == value ? .white : NKColors.textPrimary(colorScheme))
                                        .background(
                                            urgency == value ? NKColors.accentTeal : NKColors.glassBackground(colorScheme),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        Text("0: Yok · 4: Çok şiddetli")
                            .font(.caption)
                            .foregroundStyle(NKColors.textSecondary(colorScheme))
                    }
                }

                ClinicalTextEntry(
                    title: "Sonuç",
                    placeholder: "Örneğin: Tekniği uyguladım ve rahatladım",
                    text: $outcome
                )
                ClinicalTextEntry(
                    title: "Not",
                    placeholder: "Eklemek istediğiniz ayrıntılar",
                    text: $notes,
                    multiline: true
                )
                ClinicalPrimaryActionButton(
                    title: "Kaydı güvenle sakla",
                    icon: "checkmark.circle.fill",
                    isLoading: store.isSyncing,
                    action: saveRecord
                )
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)

            if !store.m5Records.isEmpty {
                Text("Son kayıtlar")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
            }
            ForEach(store.m5Records) { record in
                HStack(spacing: 12) {
                    Image(systemName: record.recordType == .naturalUrgencyEvent
                          ? "exclamationmark.circle.fill" : "doc.text.fill")
                        .foregroundStyle(NKColors.accentTeal)
                        .frame(width: 36, height: 36)
                        .background(NKColors.accentTeal.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.recordType == .naturalUrgencyEvent ? "Sıkışma olayı" : "Uygulama özeti")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        Text(record.occurredAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(NKColors.textSecondary(colorScheme))
                    }
                    Spacer()
                    Label(
                        record.storageState == .serverStored ? "Eşitlendi" : "Bekliyor",
                        systemImage: record.storageState == .serverStored ? "checkmark.icloud.fill" : "iphone"
                    )
                    .font(.caption2.bold())
                    .foregroundStyle(record.storageState == .serverStored ? NKColors.success : NKColors.warning)
                }
                .padding(14)
                .glassCard(cornerRadius: 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await store.sync() }
    }

    private func recordTypeButton(title: String, icon: String, type: M5RecordType) -> some View {
        let selected = recordType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { recordType = type }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.title3)
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .foregroundStyle(selected ? .white : NKColors.textPrimary(colorScheme))
            .background(
                selected ? NKColors.accentTeal : NKColors.glassBackground(colorScheme),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func saveRecord() {
        let payload = M5RecordPayload(
            id: UUID(),
            recordType: recordType,
            occurredAt: Date(),
            urgency: recordType == .naturalUrgencyEvent ? urgency : nil,
            outcome: outcome.isEmpty ? nil : outcome,
            notes: notes.isEmpty ? nil : notes
        )
        store.addM5Record(payload)
        outcome = ""
        notes = ""
        Task { await store.sync() }
    }
}

struct M6PatientView: View {
    let payload: M6Payload
    var body: some View {
        ClinicalReadOnlyCard(
            icon: "stethoscope",
            title: payload.title ?? "Klinik değerlendirme",
            message: payload.message ?? "Klinik ekibiniz değerlendirmeyi tamamladığında burada göreceksiniz.",
            status: payload.decision
        )
    }
}

struct M7PatientView: View {
    let payload: M7Payload
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: 14) {
            ClinicalReadOnlyCard(
                icon: "checkmark.seal.fill",
                title: payload.title ?? "Etkinleştirilen destekler",
                message: payload.message ?? "Yalnız klinik ekibinizin etkinleştirdiği paketler görünür.",
                status: nil
            )
            ForEach(payload.activations ?? []) { activation in
                VStack(alignment: .leading, spacing: 12) {
                    Text(activation.title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(NKColors.textPrimary(colorScheme))
                    ForEach(activation.instructions ?? [], id: \.self) {
                        Label($0, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(NKColors.textPrimary(colorScheme), NKColors.accentTeal)
                            .padding(11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                NKColors.glassBackground(colorScheme),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).glassCard()
            }
        }
    }
}

struct M8PatientView: View {
    let payload: M8Payload
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: 14) {
            ClinicalReadOnlyCard(
                icon: "flag.checkered",
                title: payload.title ?? "Program kapanışı",
                message: payload.message ?? "Kapanış yalnız klinik değerlendirme sonrasında tamamlanır.",
                status: payload.outcome
            )
            ForEach(payload.followUp ?? [], id: \.self) {
                Label($0, systemImage: "calendar.badge.clock")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(NKColors.textPrimary(colorScheme), NKColors.accentTeal)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            }
        }
    }
}

private struct ClinicalReadOnlyCard: View {
    let icon: String
    let title: String
    let message: String
    let status: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            GradientIconBadge(icon: icon, gradient: NKColors.coolGradient, size: 58)
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(NKColors.textPrimary(colorScheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(NKColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            if let status, !status.isEmpty {
                Label(statusLabel(status), systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(NKColors.accentTeal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(NKColors.accentTeal.opacity(0.12), in: Capsule())
            }
        }
        .padding(22).frame(maxWidth: .infinity).glassCard()
    }

    private func statusLabel(_ value: String) -> String {
        let labels = [
            "CONTINUE_CURRENT_PLAN": "Mevcut plan sürdürülecek",
            "PROGRESS_PLAN": "Plan kontrollü ilerletilecek",
            "ADJUST_PLAN": "Plan kişiselleştirilecek",
            "STEP_BACK_PLAN": "Plan geri adımla düzenlenecek",
            "TEMPORARY_HOLD": "Plan geçici olarak bekletildi",
            "RESUME_PLAN": "Plan yeniden başlatıldı",
            "TERMINATE_PLAN": "Plan sonlandırıldı",
            "COMPLETED": "Program tamamlandı",
            "CONTINUE_FOLLOW_UP": "Takiple devam edilecek",
            "REFERRED": "Yönlendirme yapıldı",
        ]
        return labels[value.uppercased()] ?? value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
