import Foundation
import Combine

@MainActor
final class ClinicalOfflineStore: ObservableObject {
    static let shared = ClinicalOfflineStore()

    @Published private(set) var diaryEvents: [BladderDiaryEvent] = []
    @Published private(set) var m5Records: [M5Record] = []
    @Published private(set) var isSyncing = false

    private let directoryURL: URL
    private var fileURL: URL
    private var activeEnrollmentId: UUID?
    private let service: ClinicalService

    private struct Snapshot: Codable {
        var enrollmentId: UUID?
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
        self.directoryURL = directory
        self.fileURL = directory.appendingPathComponent("clinical-outbox-unscoped.json")
    }

    func configure(enrollmentId: UUID) {
        guard activeEnrollmentId != enrollmentId else { return }
        activeEnrollmentId = enrollmentId
        fileURL = directoryURL.appendingPathComponent("clinical-outbox-\(enrollmentId.uuidString).json")
        diaryEvents = []
        m5Records = []
        load()
    }

    func addDiaryEvent(_ event: BladderDiaryEvent) {
        guard activeEnrollmentId != nil, event.sessionId != nil else { return }
        guard !diaryEvents.contains(where: { $0.id == event.id }) else { return }
        diaryEvents.append(event)
        persist()
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
        for var event in events {
            event.storageState = .serverStored
            if let index = diaryEvents.firstIndex(where: { $0.id == event.id }) {
                diaryEvents[index] = event
            } else {
                diaryEvents.append(event)
            }
        }
        sortAndPersist()
    }

    func sync() async {
        guard activeEnrollmentId != nil, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        for index in diaryEvents.indices where diaryEvents[index].storageState == .localOnly {
            do {
                var stored = try await service.createDiaryEvent(diaryEvents[index])
                stored.storageState = .serverStored
                if let current = diaryEvents.firstIndex(where: { $0.id == stored.id }) {
                    diaryEvents[current] = stored
                }
                persist()
            } catch {
                // Keep the UUID-backed item in the durable outbox for the next retry.
            }
        }

        for index in m5Records.indices where m5Records[index].storageState == .localOnly {
            let record = m5Records[index]
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
                if let current = m5Records.firstIndex(where: { $0.id == stored.id }) {
                    m5Records[current] = stored
                }
                persist()
            } catch {
                // Retry on a later foreground/load cycle.
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        guard snapshot.enrollmentId == activeEnrollmentId else { return }
        diaryEvents = snapshot.diaryEvents
        m5Records = snapshot.m5Records
    }

    private func sortAndPersist() {
        diaryEvents.sort { $0.occurredAt > $1.occurredAt }
        m5Records.sort { $0.occurredAt > $1.occurredAt }
        persist()
    }

    private func persist() {
        guard let activeEnrollmentId else { return }
        let snapshot = Snapshot(
            enrollmentId: activeEnrollmentId,
            diaryEvents: diaryEvents,
            m5Records: m5Records
        )
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
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
