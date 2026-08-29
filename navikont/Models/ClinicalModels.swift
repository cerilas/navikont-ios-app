import Foundation

enum ClinicalModuleCode: String, Codable, CaseIterable, Sendable {
    case m1 = "M1"
    case m2 = "M2"
    case m3 = "M3"
    case m4 = "M4"
    case m5 = "M5"
    case m6 = "M6"
    case m7 = "M7"
    case m8 = "M8"
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self).uppercased()
        self = ClinicalModuleCode(rawValue: value) ?? .unknown
    }
}

enum ClinicalScreenKind: String, Codable, Sendable {
    case article
    case audio
    case video
    case bladderDiary = "bladder_diary"
    case plan
    case teachBack = "teach_back"
    case urgencySimulation = "urgency_simulation"
    case m5Hub = "m5_hub"
    case m6Review = "m6_review"
    case m7Activation = "m7_activation"
    case m8Closure = "m8_closure"
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = ClinicalScreenKind(rawValue: value) ?? .unknown
    }
}

enum ClinicalProgressState: String, Codable, Sendable {
    case legacy
    case locked
    case available
    case inProgress = "in_progress"
    case awaitingReview = "awaiting_review"
    case safetyHold = "safety_hold"
    case completed
    case suspended
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = ClinicalProgressState(rawValue: value) ?? .unknown
    }
}

enum ClinicalGateState: String, Codable, Sendable {
    case open
    case locked
    case pending
    case blocked
    case hidden
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = ClinicalGateState(rawValue: value) ?? .unknown
    }
}

struct ClinicalScreen: Codable, Identifiable, Sendable {
    let id: UUID
    let contentId: String
    let contentVersion: String?
    let module: ClinicalModuleCode
    let kind: ClinicalScreenKind
    let title: String
    let subtitle: String?
    let body: String?
    let mediaURL: URL?
    let transcript: String?
    let teachBack: TeachBackEpisode?
    let isRequired: Bool
    let isCompleted: Bool
    let metadata: [String: AnyCodableValue]?

    enum CodingKeys: String, CodingKey {
        case id, contentId, contentVersion, module, kind, title, subtitle, body
        case mediaURL = "mediaUrl"
        case transcript, teachBack, isRequired, isCompleted, metadata
    }

    init(
        id: UUID = UUID(),
        contentId: String,
        contentVersion: String? = nil,
        module: ClinicalModuleCode,
        kind: ClinicalScreenKind,
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        mediaURL: URL? = nil,
        transcript: String? = nil,
        teachBack: TeachBackEpisode? = nil,
        isRequired: Bool = true,
        isCompleted: Bool = false,
        metadata: [String: AnyCodableValue]? = nil
    ) {
        self.id = id
        self.contentId = contentId
        self.contentVersion = contentVersion
        self.module = module
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.mediaURL = mediaURL
        self.transcript = transcript
        self.teachBack = teachBack
        self.isRequired = isRequired
        self.isCompleted = isCompleted
        self.metadata = metadata
    }
}

struct PatientClinicalState: Codable, Sendable {
    let enabled: Bool?
    let mode: String?
    let state: ClinicalProgressState?
    let currentModule: ClinicalModuleCode?
    let currentScreenId: UUID?
    let enrollmentId: UUID?
    let screens: [ClinicalScreen]?
    let updatedAt: Date?
    let testModeEnabled: Bool?

    var usesClinicalShell: Bool {
        enabled != false && mode?.lowercased() != "legacy" && state != .legacy
    }
}

struct ClinicalGate: Codable, Identifiable, Sendable {
    let id: String
    let module: ClinicalModuleCode?
    let state: ClinicalGateState
    let reasonCode: String?
    let message: String?
    let isVisible: Bool?
}

struct ActivePlanSummary: Codable, Sendable {
    let planId: UUID?
    let versionId: UUID?
    let versionNumber: Int?
    let title: String?
    let status: String?
    let publishedAt: Date?
    let summary: String?
}

struct ClinicalStateResponse: Codable, Sendable {
    let clinicalState: PatientClinicalState
    let gates: [ClinicalGate]?
    let activePlanSummary: ActivePlanSummary?
    let screens: [ClinicalScreen]?

    var resolvedScreens: [ClinicalScreen] {
        screens ?? clinicalState.screens ?? []
    }
}

struct AssetCompletionPayload: Codable, Sendable {
    let completionId: UUID
    let contentVersion: String?
    let completedAt: Date
    let metadata: [String: AnyCodableValue]?
}

struct AssetCompletionResponse: Codable, Sendable {
    let success: Bool?
    let clinicalState: PatientClinicalState?
    let gates: [ClinicalGate]?
}

enum ClinicalStorageState: String, Codable, Sendable {
    case localOnly = "LOCAL_ONLY"
    case serverStored = "SERVER_STORED"
}

enum ClinicalSyncState: Equatable, Sendable {
    case idle
    case syncing
    case failed(String)
}

enum BladderDiaryEventType: String, Codable, CaseIterable, Sendable {
    case void
    case fluid
    case leakage
    case sleepStart = "sleep_start"
    case sleepEnd = "sleep_end"
}

struct BladderDiarySession: Codable, Identifiable, Sendable {
    let id: UUID
    let status: String
    let startedAt: Date
    let endsAt: Date?
    let submittedAt: Date?
    let events: [BladderDiaryEvent]?

    var resolvedEndsAt: Date {
        endsAt ?? startedAt.addingTimeInterval(72 * 60 * 60)
    }

    var isEditable: Bool {
        ["active", "open", "in_progress", "draft"].contains(status.lowercased())
    }

    func canSubmit(events: [BladderDiaryEvent], now: Date = Date()) -> Bool {
        isEditable &&
            now >= resolvedEndsAt &&
            events.contains { $0.sessionId == id && $0.storageState == .serverStored }
    }
}

struct BladderDiaryEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let sessionId: UUID?
    let type: BladderDiaryEventType
    let occurredAt: Date
    let recordedAt: Date
    let amountMl: Double?
    let urgency: Int?
    let leakageAmount: String?
    let fluidType: String?
    let measured: Bool
    let retrospective: Bool
    let note: String?
    var storageState: ClinicalStorageState

    init(
        id: UUID = UUID(),
        sessionId: UUID?,
        type: BladderDiaryEventType,
        occurredAt: Date = Date(),
        recordedAt: Date = Date(),
        amountMl: Double? = nil,
        urgency: Int? = nil,
        leakageAmount: String? = nil,
        fluidType: String? = nil,
        measured: Bool = true,
        retrospective: Bool = false,
        note: String? = nil,
        storageState: ClinicalStorageState = .localOnly
    ) {
        self.id = id
        self.sessionId = sessionId
        self.type = type
        self.occurredAt = occurredAt
        self.recordedAt = recordedAt
        self.amountMl = amountMl
        self.urgency = urgency
        self.leakageAmount = leakageAmount
        self.fluidType = fluidType
        self.measured = measured
        self.retrospective = retrospective
        self.note = note
        self.storageState = storageState
    }
}

struct BladderDiaryEventMutation: Codable, Sendable {
    let action: String
    let occurredAt: Date?
    let amountMl: Double?
    let urgency: Int?
    let leakageAmount: String?
    let fluidType: String?
    let measured: Bool?
    let retrospective: Bool?
    let note: String?
}

struct BladderDiaryDraft: Equatable, Sendable {
    var type: BladderDiaryEventType
    var occurredAt: Date
    var amountText: String
    var urgency: Int
    var leakageAmount: String
    var fluidType: String
    var measured: Bool
    var retrospective: Bool
    var note: String

    init(
        type: BladderDiaryEventType,
        occurredAt: Date = Date(),
        amountText: String = "",
        urgency: Int = 3,
        leakageAmount: String = "",
        fluidType: String = "",
        measured: Bool = true,
        retrospective: Bool = false,
        note: String = ""
    ) {
        self.type = type
        self.occurredAt = occurredAt
        self.amountText = amountText
        self.urgency = urgency
        self.leakageAmount = leakageAmount
        self.fluidType = fluidType
        self.measured = measured
        self.retrospective = retrospective
        self.note = note
    }

    var validationMessage: String? {
        switch type {
        case .void, .fluid:
            if measured && (parsedAmount ?? 0) <= 0 {
                return "Ölçülen kayıtlar için sıfırdan büyük bir miktar girin."
            }
        case .leakage:
            if leakageAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Kaçırma miktarını seçin."
            }
        case .sleepStart, .sleepEnd:
            break
        }
        if retrospective && occurredAt > Date() {
            return "Geçmiş kayıt zamanı gelecekte olamaz."
        }
        return nil
    }

    var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    func event(sessionId: UUID, id: UUID = UUID(), recordedAt: Date = Date()) -> BladderDiaryEvent {
        let hasMeasuredAmount = (type == .void || type == .fluid) && measured
        return BladderDiaryEvent(
            id: id,
            sessionId: sessionId,
            type: type,
            occurredAt: retrospective ? occurredAt : recordedAt,
            recordedAt: recordedAt,
            amountMl: hasMeasuredAmount ? parsedAmount : nil,
            urgency: (type == .void || type == .leakage) ? urgency : nil,
            leakageAmount: type == .leakage ? leakageAmount.nilIfBlank : nil,
            fluidType: type == .fluid ? fluidType.nilIfBlank : nil,
            measured: (type == .void || type == .fluid) ? measured : false,
            retrospective: retrospective,
            note: note.nilIfBlank
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct ClinicalPlan: Codable, Identifiable, Sendable {
    let id: UUID
    let versionId: UUID?
    let versionNumber: Int?
    let title: String
    let summary: String?
    let status: String?
    let goals: [String]?
    let instructions: [String]?
    let parameters: [String: AnyCodableValue]?
    let publishedAt: Date?
}

struct TeachBackPrompt: Codable, Identifiable, Sendable {
    let id: String
    let question: String
    let options: [String]?
    let required: Bool?
}

struct TeachBackEpisode: Codable, Identifiable, Sendable {
    let id: UUID
    let planVersionId: UUID?
    let title: String?
    let prompts: [TeachBackPrompt]
    let completedAt: Date?
}

struct TeachBackResponsePayload: Codable, Sendable {
    let responseId: UUID
    let episodeId: UUID
    let answers: [String: String]
    let submittedAt: Date
}

enum M5RecordType: String, Codable, CaseIterable, Sendable {
    case naturalUrgencyEvent = "NATURAL_URGENCY_EVENT"
    case applicationSummary = "APPLICATION_SUMMARY"
}

struct M5Record: Codable, Identifiable, Sendable {
    let id: UUID
    let recordType: M5RecordType
    let occurredAt: Date
    let urgency: Int?
    let outcome: String?
    let notes: String?
    var storageState: ClinicalStorageState?
}

struct M5RecordPayload: Codable, Sendable {
    let id: UUID
    let recordType: M5RecordType
    let occurredAt: Date
    let urgency: Int?
    let outcome: String?
    let notes: String?
}

struct M5Payload: Codable, Sendable {
    let state: ClinicalProgressState?
    let records: [M5Record]?
    let summary: [String: AnyCodableValue]?
}

struct M6Payload: Codable, Sendable {
    let state: ClinicalProgressState?
    let title: String?
    let message: String?
    let decision: String?
    let decidedAt: Date?
    let awaitingActivation: Bool?
    let teachBack: TeachBackEpisode?
}

struct M7Activation: Codable, Identifiable, Sendable {
    let id: UUID
    let packageCode: String
    let title: String
    let instructions: [String]?
    let activatedAt: Date?
}

struct M7Payload: Codable, Sendable {
    let state: ClinicalProgressState?
    let title: String?
    let message: String?
    let activations: [M7Activation]?
}

struct M8Payload: Codable, Sendable {
    let state: ClinicalProgressState?
    let title: String?
    let message: String?
    let outcome: String?
    let closedAt: Date?
    let followUp: [String]?
}
