import SwiftUI
import AVKit

enum ClinicalHelpRoute: String, Identifiable {
    case technical
    case clinical
    case emergency

    var id: String { rawValue }
}

struct SafetyHelpRouter: View {
    @Environment(\.openURL) private var openURL
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Yardım", systemImage: "lifepreserver.fill")
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

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sesli içerik")
                        .font(.headline)
                    Text(isPlaying ? "Oynatılıyor" : "Dinlemeye hazır")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let transcript, !transcript.isEmpty {
                Button {
                    withAnimation { showsTranscript.toggle() }
                } label: {
                    Label(showsTranscript ? "Transkripti gizle" : "Transkripti göster",
                          systemImage: "captions.bubble.fill")
                }
                if showsTranscript {
                    Text(transcript)
                        .font(.body)
                        .lineSpacing(5)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Yayınlanmış tedavi planınız", systemImage: "doc.text.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(NKColors.accentTeal)
            Text(plan.title)
                .font(.title2.bold())
            if let summary = plan.summary {
                Text(summary).foregroundStyle(.secondary)
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
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func clinicalList(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(values, id: \.self) { value in
                Label(value, systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct TeachBackView: View {
    let episode: TeachBackEpisode
    var onSubmitted: (() -> Void)?

    @State private var answers: [String: String] = [:]
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    private let service = ClinicalService()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(episode.title ?? "Planınızı birlikte kontrol edelim")
                .font(.title2.bold())
            Text("Bu kısa kontrol bir sınav değildir; planın size açık olduğundan emin olmamıza yardımcı olur.")
                .foregroundStyle(.secondary)

            ForEach(episode.prompts) { prompt in
                VStack(alignment: .leading, spacing: 10) {
                    Text(prompt.question).font(.headline)
                    if let options = prompt.options, !options.isEmpty {
                        Picker("Yanıt", selection: binding(for: prompt.id)) {
                            Text("Seçin").tag("")
                            ForEach(options, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    } else {
                        TextField("Kendi sözlerinizle yazın", text: binding(for: prompt.id), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(16)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            }

            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }
            Button {
                submit()
            } label: {
                if isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Yanıtları gönder").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting || requiredAnswersMissing)
        }
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

    private let steps = [
        "Güvenli ve rahat bir yerde durun. İdrarınızı belirli bir süre tutma hedefi koymayın.",
        "Omuzlarınızı gevşetin ve sakin, doğal nefes alın.",
        "Size öğretilen baskılama tekniğini yalnız rahat olduğunuz ölçüde uygulayın.",
        "İhtiyaç azaldığında veya kendinizi hazır hissettiğinizde tuvalete sakin biçimde ilerleyin."
    ]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 58))
                .foregroundStyle(NKColors.accentTeal)
            Text("Sıkışma simülasyonu").font(.title2.bold())
            Text(steps[step])
                .font(.title3)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding()
            Text("Bu uygulamada geri sayım yoktur. Ağrı, kanama veya alışılmadık belirti olursa durun ve klinik yardım alın.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(step == steps.count - 1 ? "Simülasyonu tamamla" : "Hazırım, devam et") {
                if step == steps.count - 1 {
                    onComplete?()
                } else {
                    withAnimation { step += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }
}

struct BladderDiaryHubView: View {
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
            session = current
            store.mergeServerEvents(current.events ?? [])
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

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Gerçek yaşam uygulamaları").font(.title2.bold())
            Text("Doğal sıkışma olaylarını veya uygulama özetinizi kaydedin. Bu kayıt zorunlu günlük check-in değildir.")
                .foregroundStyle(.secondary)
            Picker("Kayıt türü", selection: $recordType) {
                Text("Doğal sıkışma olayı").tag(M5RecordType.naturalUrgencyEvent)
                Text("Uygulama özeti").tag(M5RecordType.applicationSummary)
            }
            .pickerStyle(.segmented)
            if recordType == .naturalUrgencyEvent {
                Stepper("Sıkışma düzeyi: \(urgency)/4", value: $urgency, in: 0...4)
            }
            TextField("Sonuç", text: $outcome).textFieldStyle(.roundedBorder)
            TextField("Not", text: $notes, axis: .vertical).textFieldStyle(.roundedBorder)
            Button("Kaydet") {
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
            .buttonStyle(.borderedProminent)
            ForEach(store.m5Records) { record in
                HStack {
                    Text(record.recordType == .naturalUrgencyEvent ? "Sıkışma olayı" : "Uygulama özeti")
                    Spacer()
                    Text(record.storageState == .serverStored ? "Sunucuda" : "Cihazda")
                        .font(.caption).foregroundStyle(record.storageState == .serverStored ? .green : .orange)
                }
                .padding(12)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .task { await store.sync() }
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
    var body: some View {
        VStack(spacing: 14) {
            ClinicalReadOnlyCard(
                icon: "checkmark.seal.fill",
                title: payload.title ?? "Etkinleştirilen destekler",
                message: payload.message ?? "Yalnız klinik ekibinizin etkinleştirdiği paketler görünür.",
                status: nil
            )
            ForEach(payload.activations ?? []) { activation in
                VStack(alignment: .leading, spacing: 8) {
                    Text(activation.title).font(.headline)
                    ForEach(activation.instructions ?? [], id: \.self) {
                        Label($0, systemImage: "checkmark")
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).glassCard()
            }
        }
    }
}

struct M8PatientView: View {
    let payload: M8Payload
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
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading).glassCard()
            }
        }
    }
}

private struct ClinicalReadOnlyCard: View {
    let icon: String
    let title: String
    let message: String
    let status: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 48)).foregroundStyle(NKColors.accentTeal)
            Text(title).font(.title2.bold()).multilineTextAlignment(.center)
            Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let status, !status.isEmpty {
                Text(status).font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 7)
                    .background(NKColors.accentTeal.opacity(0.15), in: Capsule())
            }
        }
        .padding(22).frame(maxWidth: .infinity).glassCard()
    }
}
