import SwiftUI

struct BladderDiaryHubView: View {
    let testModeAvailable: Bool?
    @StateObject private var store = ClinicalOfflineStore.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var session: BladderDiarySession?
    @State private var editor: DiaryEditorContext?
    @State private var deleteCandidate: BladderDiaryEvent?
    @State private var isLoading = true
    @State private var isStarting = false
    @State private var isSubmitting = false
    @State private var loadError: String?
    @State private var lockedSubmitTapCount = 0
    @State private var testBypassEnabled = false
    private let service = ClinicalService()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            if isLoading {
                stateCard(icon: "arrow.triangle.2.circlepath", title: "Günlük yükleniyor", message: "Oturum bilgileriniz hazırlanıyor.")
            } else if let session {
                progressCard(session)
                syncBanner
                if testBypassEnabled {
                    banner(
                        "Test modu açık: 72 saatlik bekleme koşulu bu gönderim için atlanacak.",
                        icon: "wrench.and.screwdriver.fill",
                        color: NKColors.warning
                    )
                }
                if let loadError {
                    banner(loadError, icon: "exclamationmark.triangle.fill", color: NKColors.danger)
                }
                if session.isEditable { actionGrid }
                else { reviewStatusCard(session) }
                eventList
                footer(session)
            } else if let loadError {
                errorCard(loadError)
            } else {
                stateCard(
                    icon: "calendar.badge.plus",
                    title: "Yeni günlüğe hazır mısınız?",
                    message: "72 saat boyunca olayları kaydedin. Çevrimdışı kayıtlar cihazınızda güvenle korunur.",
                    action: startButton
                )
            }
        }
        .task { await load() }
        .sheet(item: $editor) { context in
            DiaryEntrySheet(initialDraft: context.draft, isEditing: context.event != nil) { draft in
                await save(draft, replacing: context.event)
            }
        }
        .confirmationDialog(
            "Kaydı silmek istiyor musunuz?",
            isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { if !$0 { deleteCandidate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Kaydı sil", role: .destructive) {
                guard let event = deleteCandidate else { return }
                deleteCandidate = nil
                Task { _ = await store.deleteDiaryEvent(event) }
            }
            Button("Vazgeç", role: .cancel) { deleteCandidate = nil }
        } message: {
            Text("Sunucudaki kayıt iptal edilir; henüz eşitlenmemiş kayıt cihazdan kaldırılır.")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            GradientIconBadge(icon: "drop.circle.fill", gradient: NKColors.coolGradient, size: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text("72 saatlik mesane günlüğü")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                Text("Günlük yaşamınızdaki olayları kaydedin.")
                    .font(.subheadline)
                    .foregroundStyle(NKColors.textSecondary(colorScheme))
            }
            Spacer()
            if store.isSyncing {
                ProgressView().tint(NKColors.accentTeal)
                    .accessibilityLabel("Kayıtlar eşitleniyor")
            }
        }
    }

    private func progressCard(_ session: BladderDiarySession) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let total = max(session.resolvedEndsAt.timeIntervalSince(session.startedAt), 1)
            let progress = session.isEditable
                ? min(max(context.date.timeIntervalSince(session.startedAt) / total, 0), 1)
                : 1
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(statusTitle(session), systemImage: session.isEditable ? "clock.fill" : "lock.fill")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(session.isEditable ? NKColors.accentTeal : NKColors.textSecondary(colorScheme))
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.headline).monospacedDigit()
                }
                ProgressView(value: progress).tint(NKColors.accentTeal)
                    .accessibilityLabel("72 saatlik günlük ilerlemesi")
                    .accessibilityValue("\(Int(progress * 100)) yüzde")
                HStack {
                    metric(
                        session.isEditable ? "Kalan süre" : "Durum",
                        session.isEditable
                            ? remaining(until: session.resolvedEndsAt, now: context.date)
                            : "Doktor incelemesinde"
                    )
                    Spacer()
                    metric("Bu oturumdaki olay", "\(store.diaryEvents.count)", trailing: true)
                }
            }
            .padding(18)
            .glassCard()
        }
    }

    private func metric(_ caption: String, _ value: String, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 3) {
            Text(caption).font(.caption).foregroundStyle(NKColors.textSecondary(colorScheme))
            Text(value).font(.system(.title3, design: .rounded, weight: .bold)).monospacedDigit()
        }
    }

    @ViewBuilder private var syncBanner: some View {
        switch store.diarySyncState {
        case .idle:
            if store.diaryEvents.contains(where: { $0.storageState == .localOnly }) {
                banner("Bekleyen kayıtlar cihazda korunuyor.", icon: "iphone", color: NKColors.warning, retry: true)
            }
        case .syncing:
            banner("Kayıtlar güvenli biçimde eşitleniyor…", icon: "arrow.triangle.2.circlepath", color: NKColors.info)
        case .failed(let message):
            banner(message, icon: "wifi.exclamationmark", color: NKColors.danger, retry: true)
        }
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Yeni olay ekle")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                Text("Kaydetmek istediğiniz olayı seçin")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NKColors.textSecondary(colorScheme))
            }

            VStack(spacing: 10) {
                ForEach(BladderDiaryEventType.allCases, id: \.self) { type in
                    Button { editor = DiaryEditorContext(type: type) } label: {
                        HStack(spacing: 14) {
                            GradientIconBadge(icon: icon(type), gradient: gradient(type), size: 46)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(label(type))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                                Text(actionSubtitle(type))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(NKColors.textSecondary(colorScheme))
                                    .lineLimit(2)
                            }
                            .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(color(type))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .glassCard(cornerRadius: 16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("\(label(type)) olayı ekle")
                }
            }
        }
    }

    private func actionSubtitle(_ type: BladderDiaryEventType) -> String {
        switch type {
        case .void: return "Miktar ve sıkışma düzeyini kaydedin"
        case .fluid: return "İçtiğiniz sıvının türünü ve miktarını girin"
        case .leakage: return "Kaçırma miktarı ve sıkışmayı belirtin"
        case .sleepStart: return "Uykuya geçtiğiniz zamanı işaretleyin"
        case .sleepEnd: return "Uyandığınız zamanı işaretleyin"
        }
    }

    private func gradient(_ type: BladderDiaryEventType) -> LinearGradient {
        switch type {
        case .void:
            return NKColors.coolGradient
        case .fluid:
            return NKColors.tealGradient
        case .leakage:
            return NKColors.warmGradient
        case .sleepStart:
            return NKColors.primaryGradient
        case .sleepEnd:
            return LinearGradient(
                colors: [NKColors.accentAmber, Color(hex: "F97316")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var eventList: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Olay özeti").font(.system(.headline, design: .rounded, weight: .bold))
                Spacer()
                if !store.diaryEvents.isEmpty {
                    Text(summary).font(.caption2).foregroundStyle(NKColors.textSecondary(colorScheme))
                }
            }
            if store.diaryEvents.isEmpty {
                stateCard(
                    icon: "tray",
                    title: "Henüz olay yok",
                    message: session?.isEditable == true ? "İlk kaydınızı eklemek için bir olay türü seçin." : "Bu oturumda olay bulunmuyor."
                )
            } else {
                ForEach(store.diaryEvents) { event in eventRow(event) }
            }
        }
    }

    private func eventRow(_ event: BladderDiaryEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(event.type)).foregroundStyle(color(event.type))
                .frame(width: 34, height: 34).background(color(event.type).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(label(event.type)).font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(detail(event)).font(.caption).foregroundStyle(NKColors.textSecondary(colorScheme))
                Text(event.occurredAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(NKColors.textTertiary(colorScheme))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 7) {
                Label(event.storageState == .serverStored ? "Eşitlendi" : "Bekliyor",
                      systemImage: event.storageState == .serverStored ? "checkmark.icloud.fill" : "iphone")
                    .font(.caption2.bold())
                    .foregroundStyle(event.storageState == .serverStored ? NKColors.success : NKColors.warning)
                if session?.isEditable == true {
                    Menu {
                        Button { editor = DiaryEditorContext(event: event) } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        Button(role: .destructive) { deleteCandidate = event } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.title3)
                    }
                    .accessibilityLabel("\(label(event.type)) kayıt seçenekleri")
                }
            }
        }
        .padding(13)
        .background(NKColors.glassBackground(colorScheme), in: RoundedRectangle(cornerRadius: 15))
    }

    @ViewBuilder private func footer(_ session: BladderDiarySession) -> some View {
        if session.isEditable {
            VStack(spacing: 9) {
                Button {
                    if canSubmit {
                        submit()
                    } else {
                        handleLockedSubmitTap(session)
                    }
                } label: {
                    HStack {
                        if isSubmitting { ProgressView().tint(.white) }
                        Label("Klinik incelemeye gönder", systemImage: "paperplane.fill")
                    }
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 15).foregroundStyle(.white)
                    .background(canSubmit ? NKColors.tealGradient : disabledGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isSubmitting || store.isSyncing)
                if !canSubmit {
                    Text(submitRequirement(session)).font(.caption)
                        .foregroundStyle(NKColors.textSecondary(colorScheme)).multilineTextAlignment(.center)
                }
            }
        }
    }

    private var startButton: some View {
        Button { start() } label: {
            HStack {
                if isStarting { ProgressView().tint(.white) }
                Label(session == nil ? "72 saatlik günlüğü başlat" : "Yeni günlük başlat", systemImage: "plus.circle.fill")
            }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity).padding(.vertical, 14).foregroundStyle(.white)
            .background(NKColors.primaryGradient).clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(ScaleButtonStyle()).disabled(isStarting)
    }

    private func stateCard<Action: View>(
        icon: String, title: String, message: String, action: Action
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(NKColors.accentTeal)
            Text(title).font(.system(.title3, design: .rounded, weight: .bold))
            Text(message).font(.subheadline).foregroundStyle(NKColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
            action
        }
        .frame(maxWidth: .infinity).padding(22).glassCard()
    }

    private func stateCard(icon: String, title: String, message: String) -> some View {
        stateCard(icon: icon, title: title, message: message, action: EmptyView())
    }

    private func errorCard(_ message: String) -> some View {
        stateCard(
            icon: "wifi.exclamationmark",
            title: "Günlük yüklenemedi",
            message: message,
            action: ClinicalSecondaryActionButton(
                title: "Tekrar dene",
                icon: "arrow.clockwise",
                action: { Task { await load() } }
            )
        )
    }

    private func reviewStatusCard(_ session: BladderDiarySession) -> some View {
        VStack(spacing: 14) {
            GradientIconBadge(
                icon: "doc.text.magnifyingglass",
                gradient: NKColors.coolGradient,
                size: 52
            )
            Text(statusTitle(session))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Doktorunuz günlük kayıtlarınızı değerlendiriyor. İnceleme tamamlandığında klinik programınız bir sonraki adıma geçecek.")
                .font(.subheadline)
                .foregroundStyle(NKColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard()
    }

    private func banner(_ text: String, icon: String, color: Color, retry: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text).font(.caption).foregroundStyle(NKColors.textSecondary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            if retry {
                Button("Tekrar eşitle") { Task { _ = await store.sync() } }
                    .font(.caption.bold()).foregroundStyle(color)
            }
        }
        .padding(12).background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
    }

    private func load() async {
        isLoading = true; loadError = nil
        do {
            session = try await service.fetchCurrentDiarySession()
            store.cacheDiarySession(session)
            if let session {
                store.mergeServerEvents(session.events ?? [])
                if session.isEditable { _ = await store.sync() }
            }
        } catch {
            if session == nil, let cachedSession = store.cachedDiarySession {
                session = cachedSession
                store.activateDiarySession(cachedSession.id)
            }
            loadError = "Sunucuya ulaşılamadı: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func start() {
        isStarting = true; loadError = nil
        Task {
            do {
                let started = try await service.startDiarySession()
                session = started
                store.cacheDiarySession(started)
                store.mergeServerEvents(started.events ?? [])
            } catch {
                loadError = "Yeni günlük başlatılamadı: \(error.localizedDescription)"
            }
            isStarting = false
        }
    }

    private func save(_ draft: BladderDiaryDraft, replacing old: BladderDiaryEvent?) async -> Bool {
        guard let session, session.isEditable else { return false }
        let event = draft.event(sessionId: session.id, id: old?.id ?? UUID(), recordedAt: old?.recordedAt ?? Date())
        if old != nil { return await store.updateDiaryEvent(event) }
        store.addDiaryEvent(event)
        _ = await store.sync()
        return true
    }

    private func submit() {
        guard let session else { return }
        isSubmitting = true; loadError = nil
        Task {
            let synced = await store.sync()
            guard synced, !store.diaryEvents.contains(where: { $0.storageState == .localOnly }) else {
                loadError = "Gönderim durduruldu. Bekleyen kayıtları eşitleyip tekrar deneyin."
                isSubmitting = false; return
            }
            guard canSubmit else {
                loadError = "72 saat ve en az bir eşitlenmiş kayıt gereklidir."
                isSubmitting = false; return
            }
            do {
                let submitted = try await service.submitDiary(
                    sessionId: session.id,
                    testBypass: testBypassEnabled
                )
                self.session = submitted
                store.cacheDiarySession(submitted)
                testBypassEnabled = false
                lockedSubmitTapCount = 0
            }
            catch { loadError = "Günlük gönderilemedi: \(error.localizedDescription)" }
            isSubmitting = false
        }
    }

    private var canSubmit: Bool {
        guard let session else { return false }
        let hasOnlySyncedEvents =
            store.diaryEvents.contains { $0.storageState == .serverStored } &&
            !store.diaryEvents.contains { $0.storageState == .localOnly } &&
            store.failedDiaryEventIDs.isEmpty
        let regularSubmission = session.canSubmit(events: store.diaryEvents)
        let testSubmission = testModeAvailable == true && testBypassEnabled && session.isEditable
        return hasOnlySyncedEvents && (regularSubmission || testSubmission)
    }

    private func submitRequirement(_ session: BladderDiarySession) -> String {
        if testBypassEnabled && testModeAvailable == true {
            return "Test modu açık. Eşitlenmiş en az bir olay bulunduğunda gönderebilirsiniz."
        }
        if Date() < session.resolvedEndsAt { return "Gönderim için \(remaining(until: session.resolvedEndsAt, now: Date())) daha kayıt tutun." }
        if !store.diaryEvents.contains(where: { $0.storageState == .serverStored }) { return "En az bir olayın sunucuya eşitlenmesi gerekir." }
        return "Bekleyen kayıtları eşitleyip tekrar deneyin."
    }

    private func handleLockedSubmitTap(_ session: BladderDiarySession) {
        guard session.isEditable, Date() < session.resolvedEndsAt else { return }
        lockedSubmitTapCount += 1
        guard lockedSubmitTapCount >= 5 else { return }
        lockedSubmitTapCount = 0
        if testModeAvailable == true {
            testBypassEnabled = true
            loadError = nil
        } else if testModeAvailable == nil {
            loadError = "Test modu bilgisi sunucudan alınamadı. Backend güncellemesi yayımlanmalı."
        } else {
            loadError = "Bu hasta için test modu doktor veya admin panelinden açılmamış."
        }
    }

    private var summary: String {
        let count: (BladderDiaryEventType) -> Int = { type in store.diaryEvents.filter { $0.type == type }.count }
        return "\(count(.void)) işeme • \(count(.fluid)) sıvı • \(count(.leakage)) kaçırma"
    }

    private func detail(_ event: BladderDiaryEvent) -> String {
        var values: [String] = []
        if let amount = event.amountMl { values.append("\(amount.formatted()) ml") }
        if (event.type == .void || event.type == .fluid) && !event.measured { values.append("Ölçülmedi") }
        if let leakage = event.leakageAmount { values.append(leakage) }
        if let fluid = event.fluidType { values.append(fluid) }
        if let urgency = event.urgency { values.append("Sıkışma \(urgency)/4") }
        return values.isEmpty ? "Ek ayrıntı yok" : values.joined(separator: " • ")
    }

    private func remaining(until end: Date, now: Date) -> String {
        let seconds = max(Int(end.timeIntervalSince(now)), 0)
        return seconds == 0 ? "Gönderime hazır" : "\(seconds / 3600) sa \((seconds % 3600) / 60) dk"
    }

    private func statusTitle(_ session: BladderDiarySession) -> String {
        switch session.status.lowercased() {
        case "active", "open", "in_progress", "draft": return "Kayıt devam ediyor"
        case "submitted", "under_review": return "Günlük verileriniz inceleniyor"
        case "reviewed", "approved": return "İnceleme tamamlandı"
        case "closed": return "Oturum kapatıldı"
        default: return "Salt okunur oturum"
        }
    }

    private func label(_ type: BladderDiaryEventType) -> String {
        switch type {
        case .void: return "İşeme"
        case .fluid: return "Sıvı alımı"
        case .leakage: return "Kaçırma"
        case .sleepStart: return "Uyku başlangıcı"
        case .sleepEnd: return "Uyku bitişi"
        }
    }

    private func icon(_ type: BladderDiaryEventType) -> String {
        switch type {
        case .void: return "drop.fill"
        case .fluid: return "cup.and.saucer.fill"
        case .leakage: return "exclamationmark.circle.fill"
        case .sleepStart: return "moon.fill"
        case .sleepEnd: return "sun.max.fill"
        }
    }

    private func color(_ type: BladderDiaryEventType) -> Color {
        switch type {
        case .void: return NKColors.accentCyan
        case .fluid: return NKColors.accentTeal
        case .leakage: return NKColors.accentRose
        case .sleepStart: return NKColors.primaryGradientStart
        case .sleepEnd: return NKColors.accentAmber
        }
    }

    private var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [NKColors.textTertiary(colorScheme).opacity(0.55)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct DiaryEditorContext: Identifiable {
    let id = UUID()
    let event: BladderDiaryEvent?
    let draft: BladderDiaryDraft

    init(type: BladderDiaryEventType) {
        event = nil
        draft = BladderDiaryDraft(type: type)
    }

    init(event: BladderDiaryEvent) {
        self.event = event
        draft = BladderDiaryDraft(
            type: event.type,
            occurredAt: event.occurredAt,
            amountText: event.amountMl.map { String($0) } ?? "",
            urgency: event.urgency ?? 3,
            leakageAmount: event.leakageAmount ?? "",
            fluidType: event.fluidType ?? "",
            measured: event.measured,
            retrospective: event.retrospective,
            note: event.note ?? ""
        )
    }
}

private struct DiaryEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var draft: BladderDiaryDraft
    @State private var message: String?
    @State private var isSaving = false
    let isEditing: Bool
    let onSave: (BladderDiaryDraft) async -> Bool

    init(initialDraft: BladderDiaryDraft, isEditing: Bool, onSave: @escaping (BladderDiaryDraft) async -> Bool) {
        _draft = State(initialValue: initialDraft)
        self.isEditing = isEditing
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(spacing: 14) {
                        GradientIconBadge(icon: icon, gradient: gradient, size: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(NKColors.textPrimary(colorScheme))
                            Text(isEditing ? "Kayıt ayrıntılarını güncelleyin" : "Olay ayrıntılarını kaydedin")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(NKColors.textSecondary(colorScheme))
                        }
                    }

                    if draft.type == .void || draft.type == .fluid {
                        formCard {
                            toggleRow(
                                title: "Miktarı ölçtüm",
                                subtitle: "Yaklaşık değil, ölçülen değeri girin",
                                icon: "ruler.fill",
                                isOn: $draft.measured
                            )
                            if draft.measured {
                                fieldLabel("Miktar", icon: "drop.fill")
                                HStack(spacing: 10) {
                                    TextField(
                                        "",
                                        text: $draft.amountText,
                                        prompt: Text("Örn. 250")
                                            .foregroundStyle(NKColors.textTertiary(colorScheme))
                                    )
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                                    Text("ml")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(NKColors.textSecondary(colorScheme))
                                }
                                .padding(.horizontal, 15)
                                .frame(height: 54)
                                .background(fieldBackground)
                            } else {
                                Label("Miktar alanı boş bırakılacak", systemImage: "info.circle.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(NKColors.textSecondary(colorScheme))
                            }
                            if draft.type == .fluid {
                                fieldLabel("Sıvı türü", icon: "cup.and.saucer.fill", optional: true)
                                styledTextField("Örn. su, kahve veya çay", text: $draft.fluidType)
                            }
                        }
                    }
                    if draft.type == .leakage {
                        formCard {
                            fieldLabel("Kaçırma miktarı", icon: "drop.triangle.fill")
                            HStack(spacing: 8) {
                                ForEach(["Az", "Orta", "Çok"], id: \.self) { amount in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.16)) {
                                            draft.leakageAmount = amount
                                        }
                                    } label: {
                                        Text(amount)
                                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .foregroundStyle(
                                                draft.leakageAmount == amount
                                                    ? .white
                                                    : NKColors.textPrimary(colorScheme)
                                            )
                                            .background(
                                                draft.leakageAmount == amount
                                                    ? NKColors.accentTeal
                                                    : NKColors.glassBackground(colorScheme),
                                                in: RoundedRectangle(cornerRadius: 12)
                                            )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                    }
                    if draft.type == .void || draft.type == .leakage {
                        formCard {
                            fieldLabel("Sıkışma düzeyi", icon: "waveform.path.ecg")
                            Text(urgencyDescription)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(NKColors.textSecondary(colorScheme))
                            HStack(spacing: 8) {
                                ForEach(0...4, id: \.self) { value in
                                    Button {
                                        withAnimation(.spring(response: 0.25)) { draft.urgency = value }
                                    } label: {
                                        Text("\(value)")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(draft.urgency == value ? .white : NKColors.textSecondary(colorScheme))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(draft.urgency == value
                                                          ? NKColors.accentTeal
                                                          : NKColors.glassBackground(colorScheme))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(
                                                                draft.urgency == value
                                                                    ? NKColors.accentTeal
                                                                    : NKColors.glassBorder(colorScheme),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Sıkışma düzeyi \(value)")
                                }
                            }
                        }
                    }
                    formCard {
                        toggleRow(
                            title: "Geçmiş bir olay",
                            subtitle: "Olayı gerçekleştiği zamanla kaydedin",
                            icon: "clock.arrow.circlepath",
                            isOn: $draft.retrospective
                        )
                        if draft.retrospective {
                            Divider().overlay(NKColors.glassBorder(colorScheme))
                            DatePicker(
                                "Gerçekleşme zamanı",
                                selection: $draft.occurredAt,
                                in: ...Date(),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .font(.system(size: 14, weight: .semibold))
                            .tint(NKColors.accentTeal)
                        }
                    }
                    formCard {
                        fieldLabel("Not", icon: "text.alignleft", optional: true)
                        TextField(
                            "",
                            text: $draft.note,
                            prompt: Text("Bu olayla ilgili eklemek istediğiniz ayrıntılar")
                                .foregroundStyle(NKColors.textTertiary(colorScheme)),
                            axis: .vertical
                        )
                        .lineLimit(4...7)
                        .foregroundStyle(NKColors.textPrimary(colorScheme))
                        .padding(15)
                        .frame(minHeight: 108, alignment: .topLeading)
                        .background(fieldBackground)
                    }
                    if let message {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(NKColors.danger)
                            .padding(13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NKColors.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
                    }
                    Button { submit() } label: {
                        HStack {
                            if isSaving { ProgressView().tint(.white) }
                            Text(isEditing ? "Değişiklikleri kaydet" : "Olayı kaydet")
                        }
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 15).foregroundStyle(.white)
                        .background(NKColors.tealGradient).clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle()).disabled(isSaving)
                }
                .padding(20)
            }
            .background(NKColors.bgPrimary(colorScheme).ignoresSafeArea())
            .navigationTitle(isEditing ? "Kaydı düzenle" : "Yeni olay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Label("Vazgeç", systemImage: "xmark.circle.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(NKColors.textPrimary(colorScheme))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func fieldLabel(_ title: String, icon: String, optional: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(NKColors.accentTeal)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(NKColors.textPrimary(colorScheme))
            if optional {
                Text("İsteğe bağlı")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(NKColors.textTertiary(colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NKColors.glassBackground(colorScheme), in: Capsule())
            }
        }
    }

    private func styledTextField(_ prompt: String, text: Binding<String>) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(prompt).foregroundStyle(NKColors.textTertiary(colorScheme))
        )
        .foregroundStyle(NKColors.textPrimary(colorScheme))
        .padding(.horizontal, 15)
        .frame(height: 54)
        .background(fieldBackground)
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(NKColors.accentTeal)
                .frame(width: 36, height: 36)
                .background(NKColors.accentTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(NKColors.textPrimary(colorScheme))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NKColors.textSecondary(colorScheme))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(NKColors.accentTeal)
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(NKColors.glassBackground(colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
            )
    }

    private var urgencyDescription: String {
        switch draft.urgency {
        case 0: return "Sıkışma yok"
        case 1: return "Hafif, kolayca ertelenebilir"
        case 2: return "Orta, dikkat dağıtıyor"
        case 3: return "Güçlü, ertelemek zor"
        default: return "Çok güçlü, hemen tuvalet ihtiyacı"
        }
    }

    private var icon: String {
        switch draft.type {
        case .void: return "drop.fill"
        case .fluid: return "cup.and.saucer.fill"
        case .leakage: return "exclamationmark.circle.fill"
        case .sleepStart: return "moon.fill"
        case .sleepEnd: return "sun.max.fill"
        }
    }

    private var gradient: LinearGradient {
        switch draft.type {
        case .void: return NKColors.coolGradient
        case .fluid: return NKColors.tealGradient
        case .leakage: return NKColors.warmGradient
        case .sleepStart: return NKColors.primaryGradient
        case .sleepEnd:
            return LinearGradient(
                colors: [NKColors.accentAmber, Color(hex: "F97316")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13, content: content)
            .padding(16)
            .glassCard(cornerRadius: 18)
    }

    private func submit() {
        if let validation = draft.validationMessage { message = validation; return }
        message = nil; isSaving = true
        Task {
            if await onSave(draft) { dismiss() }
            else { message = "Kayıt kaydedilemedi. Bağlantınızı kontrol edip tekrar deneyin."; isSaving = false }
        }
    }

    private var title: String {
        switch draft.type {
        case .void: return "İşeme"
        case .fluid: return "Sıvı alımı"
        case .leakage: return "Kaçırma"
        case .sleepStart: return "Uyku başlangıcı"
        case .sleepEnd: return "Uyku bitişi"
        }
    }
}
