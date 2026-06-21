import Foundation

// MARK: - Check-in Models

struct CheckinTemplate: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String?
    let description: String?
    let fields: [CheckinField]?
}

struct CheckinField: Codable, Identifiable, Sendable {
    let id: UUID
    let fieldKey: String?
    let fieldType: String  // number, text, boolean, scale, slider, single_choice, multiple_choice, date, time
    let label: String
    let description: String?
    let placeholder: String?
    let isRequired: Bool?
    let sortOrder: Int?
    let validationRules: AnyCodableValue?
    let options: [CheckinFieldOption]?

    var required: Bool {
        isRequired ?? false
    }
}

struct CheckinFieldOption: Codable, Identifiable, Sendable {
    let id: UUID
    let label: String
    let value: String?
    let sortOrder: Int?
}

// MARK: - Check-in Submission

struct CheckinSubmission: Codable, Sendable {
    let checkinTemplateId: UUID
    let values: [CheckinValue]
}

struct CheckinValue: Codable, Sendable {
    let fieldId: UUID
    let value: String
}

struct CheckinSubmissionResponse: Codable, Sendable {
    let id: UUID?
    let streakCount: Int?
    let message: String?
}
