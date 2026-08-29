import Foundation
import Combine

@MainActor
final class ClinicalOfflineStore: ObservableObject {
    static let shared = ClinicalOfflineStore()

    @Published private(set) var diaryEvents: [BladderDiaryEvent] = []
    @Published private(set) var m5Records: [M5Record] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var diarySyncState: ClinicalSyncState = .idle
    @Published private(set) var failedDiaryEventIDs: Set<UUID> = []
    @Published private(set) var cachedDiarySession: BladderDiarySession?

    private let directoryURL: URL
    private var fileURL: URL
    private var activeEnrollmentId: UUID?
    private var activeSessionId: UUID?
    private var allDiaryEvents: [BladderDiaryEvent] = []
    private let service: ClinicalService

    private struct Snapshot: Codable {
        var enrollmentId: UUID?
        var diarySession: BladderDiarySession?
        var diaryEvents: [BladderDiaryEvent]
        var m5Records: [M5Record]
    }

    init(service: ClinicalService? = nil, fileManager: FileManager = .default) {
        self.service = service ?? ClinicalService()
        let root = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        let directory = root.appendingPathComponent("NaviKontClinical", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: directory.path
        )
        self.directoryURL = directory
        self.fileURL = directory.appendingPathComponent("clinical-outbox-unscoped.json")
    }

    func configure(enrollmentId: UUID) {
        guard activeEnrollmentId != enrollmentId else { return }
        activeEnrollmentId = enrollmentId
        activeSessionId = nil
        fileURL = directoryURL.appendingPathComponent("clinical-outbox-\(enrollmentId.uuidString).json")
        diaryEvents = []
        allDiaryEvents = []
        m5Records = []
        cachedDiarySession = nil
        resetSyncState()
        load()
    }

    func activateDiarySession(_ sessionId: UUID?) {
        guard activeSessionId != sessionId else { return }
        activeSessionId = sessionId
        isSyncing = false
        refreshVisibleDiaryEvents()
        resetSyncState()
    }

    func cacheDiarySession(_ session: BladderDiarySession?) {
        cachedDiarySession = session
        activateDiarySession(session?.id)
        persist()
    }

    func deactivate() {
        activeEnrollmentId = nil
        activeSessionId = nil
        fileURL = directoryURL.appendingPathComponent("clinical-outbox-unscoped.json")
        allDiaryEvents = []
        diaryEvents = []
        m5Records = []
        cachedDiarySession = nil
        isSyncing = false
        resetSyncState()
    }

    func addDiaryEvent(_ event: BladderDiaryEvent) {
        guard activeEnrollmentId != nil,
              let sessionId = event.sessionId,
              sessionId == activeSessionId else { return }
        guard !allDiaryEvents.contains(where: { $0.id == event.id }) else { return }
        allDiaryEvents.append(event)
        sortAndPersist()
    }

    func addM5Record(_ payload: M5RecordPayload) {
        guard activeEnrollmentId != nil else { return }
        guard !m5Records.contains(where: { $0.id == payload.id }) else { return }
        m5Records.append(M5Record(
            id: payload.id,
            recordType: payload.recordType,
            occurredAt: payload.occurredAt,
            urgency: payload.urgency,
            outcome: payload.outcome,
            notes: payload.notes,
            storageState: .localOnly
        ))
        persist()
    }

    func mergeServerEvents(_ events: [BladderDiaryEvent]) {
        guard let activeSessionId else { return }
        for serverEvent in events {
            guard serverEvent.sessionId == nil || serverEvent.sessionId == activeSessionId else { continue }
            var event = scoped(serverEvent, to: activeSessionId)
            event.storageState = .serverStored
            if let index = allDiaryEvents.firstIndex(where: { $0.id == event.id }) {
                allDiaryEvents[index] = event
            } else {
                allDiaryEvents.append(event)
            }
        }
        sortAndPersist()
    }

    @discardableResult
    func sync() async -> Bool {
        guard !isSyncing else {
            return failedDiaryEventIDs.isEmpty
        }
        guard let enrollmentId = activeEnrollmentId else { return false }
        isSyncing = true
        diarySyncState = .syncing
        failedDiaryEventIDs = []
        var messages: [String] = []

        let sessionId = activeSessionId
        let pendingDiaryEvents = allDiaryEvents.filter {
            $0.sessionId == sessionId && $0.storageState == .localOnly
        }
        for event in pendingDiaryEvents {
            do {
                var stored = try await service.createDiaryEvent(event)
                stored.storageState = .serverStored
                guard activeEnrollmentId == enrollmentId, activeSessionId == sessionId else {
                    continue
                }
                if let current = allDiaryEvents.firstIndex(where: { $0.id == event.id }) {
                    allDiaryEvents[current] = normalized(stored, fallback: event)
                }
                persist()
            } catch {
                guard activeEnrollmentId == enrollmentId, activeSessionId == sessionId else {
                    continue
                }
                failedDiaryEventIDs.insert(event.id)
                messages.append(error.localizedDescription)
            }
        }

        let pendingM5Records = m5Records.filter { $0.storageState == .localOnly }
        for record in pendingM5Records {
            let payload = M5RecordPayload(
                id: record.id,
                recordType: record.recordType,
                occurredAt: record.occurredAt,
                urgency: record.urgency,
                outcome: record.outcome,
                notes: record.notes
            )
            do {
                var stored = try await service.createM5Record(payload)
                stored.storageState = .serverStored
                guard activeEnrollmentId == enrollmentId else { continue }
                if let current = m5Records.firstIndex(where: { $0.id == stored.id }) {
                    m5Records[current] = stored
                }
                persist()
            } catch {
                guard activeEnrollmentId == enrollmentId else { continue }
                messages.append(error.localizedDescription)
            }
        }

        guard activeEnrollmentId == enrollmentId, activeSessionId == sessionId else {
            return false
        }
        refreshVisibleDiaryEvents()
        isSyncing = false
        if messages.isEmpty {
            diarySyncState = .idle
            return true
        }
        let message = "Bazı kayıtlar eşitlenemedi: \(messages.first ?? "Bağlantınızı kontrol edip tekrar deneyin.")"
        diarySyncState = .failed(message)
        return false
    }

    @discardableResult
    func updateDiaryEvent(_ replacement: BladderDiaryEvent) async -> Bool {
        guard let enrollmentId = activeEnrollmentId,
              let sessionId = activeSessionId,
              replacement.sessionId == sessionId,
              let existing = allDiaryEvents.first(where: { $0.id == replacement.id }) else {
            return false
        }

        if existing.storageState == .localOnly {
            replace(replacement, storageState: .localOnly)
            failedDiaryEventIDs.remove(replacement.id)
            return true
        }

        diarySyncState = .syncing
        do {
            let stored = try await service.mutateDiaryEvent(
                id: replacement.id,
                mutation: BladderDiaryEventMutation(
                    action: "update",
                    occurredAt: replacement.occurredAt,
                    amountMl: replacement.amountMl,
                    urgency: replacement.urgency,
                    leakageAmount: replacement.leakageAmount,
                    fluidType: replacement.fluidType,
                    measured: replacement.measured,
                    retrospective: replacement.retrospective,
                    note: replacement.note
                )
            )
            guard activeEnrollmentId == enrollmentId, activeSessionId == sessionId else { return false }
            replace(normalized(stored, fallback: replacement), storageState: .serverStored)
            diarySyncState = .idle
            return true
        } catch {
            guard activeEnrollmentId == enrollmentId, activeSessionId == sessionId else { return false }
            diarySyncState = .failed("Kayıt güncellenemedi: \(error.localizedDescription)")
            failedDiaryEventIDs.insert(replacement.id)
            return false
        }
    }

    @discardableResult
    func deleteDiaryEvent(_ event: BladderDiaryEvent) async -> Bool {
        guard let enrollmentId = activeEnrollmentId,
              let sessionId = activeSessionId,
              event.sessionId == sessionId else { return false }

        if event.storageState == .localOnly {
            removeDiaryEvent(id: event.id)
            return true
        }

        diarySyncState = .syncing
        do {
            _ = try await service.mutateDiaryEvent(
                id: event.id,
                mutation: BladderDiaryEventMutation(
                    action: "void",
                    occurredAt: nil,
                    amountMl: nil,
                    urgency: nil,
                    leakageAmount: nil,
                    fluidType: nil,
                    measured: nil,
                    retrospective: nil,
                    note: nil
                )
            )
            guard activeEnrollmentId == enrollmentId, activeSessionId == sessionId else { return false }
            removeDiaryEvent(id: event.id)
            diarySyncState = .idle
            return true
        } catch {
            guard activeEnrollmentId == enrollmentId, activeSessionId == sessionId else { return false }
            diarySyncState = .failed("Kayıt silinemedi: \(error.localizedDescription)")
            failedDiaryEventIDs.insert(event.id)
            return false
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        guard snapshot.enrollmentId == activeEnrollmentId else { return }
        cachedDiarySession = snapshot.diarySession
        activeSessionId = snapshot.diarySession?.id
        allDiaryEvents = snapshot.diaryEvents
        m5Records = snapshot.m5Records
        refreshVisibleDiaryEvents()
    }

    private func sortAndPersist() {
        allDiaryEvents.sort { $0.occurredAt > $1.occurredAt }
        m5Records.sort { $0.occurredAt > $1.occurredAt }
        refreshVisibleDiaryEvents()
        persist()
    }

    private func persist() {
        guard let activeEnrollmentId else { return }
        let snapshot = Snapshot(
            enrollmentId: activeEnrollmentId,
            diarySession: cachedDiarySession,
            diaryEvents: allDiaryEvents,
            m5Records: m5Records
        )
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            diarySyncState = .failed("Cihazdaki güvenli kayıt dosyası güncellenemedi: \(error.localizedDescription)")
        }
    }

    private func refreshVisibleDiaryEvents() {
        diaryEvents = allDiaryEvents
            .filter { $0.sessionId == activeSessionId }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    private func replace(_ event: BladderDiaryEvent, storageState: ClinicalStorageState) {
        var event = event
        event.storageState = storageState
        if let index = allDiaryEvents.firstIndex(where: { $0.id == event.id }) {
            allDiaryEvents[index] = event
        }
        sortAndPersist()
    }

    private func removeDiaryEvent(id: UUID) {
        allDiaryEvents.removeAll { $0.id == id }
        failedDiaryEventIDs.remove(id)
        sortAndPersist()
    }

    private func normalized(
        _ stored: BladderDiaryEvent,
        fallback: BladderDiaryEvent
    ) -> BladderDiaryEvent {
        BladderDiaryEvent(
            id: stored.id,
            sessionId: stored.sessionId ?? fallback.sessionId,
            type: stored.type,
            occurredAt: stored.occurredAt,
            recordedAt: stored.recordedAt,
            amountMl: stored.amountMl,
            urgency: stored.urgency,
            leakageAmount: stored.leakageAmount,
            fluidType: stored.fluidType ?? fallback.fluidType,
            measured: stored.measured,
            retrospective: stored.retrospective,
            note: stored.note,
            storageState: .serverStored
        )
    }

    private func scoped(_ event: BladderDiaryEvent, to sessionId: UUID) -> BladderDiaryEvent {
        BladderDiaryEvent(
            id: event.id,
            sessionId: sessionId,
            type: event.type,
            occurredAt: event.occurredAt,
            recordedAt: event.recordedAt,
            amountMl: event.amountMl,
            urgency: event.urgency,
            leakageAmount: event.leakageAmount,
            fluidType: event.fluidType,
            measured: event.measured,
            retrospective: event.retrospective,
            note: event.note,
            storageState: event.storageState
        )
    }

    private func resetSyncState() {
        diarySyncState = .idle
        failedDiaryEventIDs = []
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
