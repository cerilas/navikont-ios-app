import Foundation

struct JourneyStep: Codable, Identifiable, Sendable {
    /// Maps to stepId from backend (today's tasks API)
    let id: UUID
    let journeyId: UUID?
    let dayNumber: Int
    let orderInDay: Int
    let isRequired: Bool?
    let module: Module
    var isCompleted: Bool

    /// Convenience: whether this step is required
    var required: Bool {
        isRequired ?? module.required
    }

    // Backend returns tasks in a flat structure (stepId, moduleTitle, etc.)
    // We implement a custom decoder to handle both nested (module:{}) and flat formats.
    enum CodingKeys: String, CodingKey {
        case id = "stepId"
        case journeyId
        case dayNumber
        case orderInDay
        case isRequired
        case module
        case isCompleted
        // Flat backend fields (today API)
        case moduleId
        case moduleVersionId
        case moduleName
        case moduleType
        case moduleTitle
        case moduleSubtitle
        case moduleContent
        case moduleSettings
        case completionStatus
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id: prefer "stepId", fall back to "id" via alternate decoder
        if let stepId = try? c.decode(UUID.self, forKey: .id) {
            id = stepId
        } else {
            // Try decoding as plain "id" using original container
            let plain = try decoder.container(keyedBy: PlainKeys.self)
            id = try plain.decode(UUID.self, forKey: .id)
        }

        journeyId = try? c.decode(UUID.self, forKey: .journeyId)
        dayNumber = (try? c.decode(Int.self, forKey: .dayNumber)) ?? 1
        orderInDay = (try? c.decode(Int.self, forKey: .orderInDay)) ?? 1
        isRequired = try? c.decode(Bool.self, forKey: .isRequired)

        // Decode isCompleted from completionStatus or isCompleted field
        if let status = try? c.decode(String.self, forKey: .completionStatus) {
            isCompleted = status == "completed"
        } else {
            isCompleted = (try? c.decode(Bool.self, forKey: .isCompleted)) ?? false
        }

        // Try nested module first, then flat fields
        if let nested = try? c.decode(Module.self, forKey: .module) {
            module = nested
        } else {
            // Reconstruct Module from flat fields
            let versionId = (try? c.decode(UUID.self, forKey: .moduleVersionId))
                ?? (try? c.decode(UUID.self, forKey: .moduleId))
                ?? UUID()
            let mid = try? c.decode(UUID.self, forKey: .moduleId)
            let title = (try? c.decode(String.self, forKey: .moduleTitle)) ?? "Modül"
            let subtitle = try? c.decode(String.self, forKey: .moduleSubtitle)
            let mtype = (try? c.decode(String.self, forKey: .moduleType)) ?? "article"
            let content = try? c.decode(ModuleContent.self, forKey: .moduleContent)

            module = Module(
                id: versionId,
                moduleId: mid,
                title: title,
                subtitle: subtitle,
                moduleType: mtype,
                content: content,
                isRequired: isRequired
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: PlainKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(journeyId, forKey: .journeyId)
        try c.encode(dayNumber, forKey: .dayNumber)
        try c.encode(orderInDay, forKey: .orderInDay)
        try c.encodeIfPresent(isRequired, forKey: .isRequired)
        try c.encode(module, forKey: .module)
        try c.encode(isCompleted, forKey: .isCompleted)
    }

    private enum PlainKeys: String, CodingKey {
        case id, journeyId, dayNumber, orderInDay, isRequired, module, isCompleted
    }
}
