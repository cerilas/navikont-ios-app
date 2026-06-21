import Foundation

// MARK: - Questionnaire Models

struct QuestionnaireVersion: Codable, Identifiable, Sendable {
    let id: UUID
    let questionnaireId: UUID?
    let title: String
    let descriptionHtml: String?
    let scoringMethod: AnyCodableValue?
    let riskRules: AnyCodableValue?
    var questions: [Question]?
}

struct QuestionnaireResponseWrapper: Codable, Sendable {
    let questionnaire: QuestionnaireVersion
    let questions: [Question]?
    let previousResponse: AnyCodableValue?
}

struct Question: Codable, Identifiable, Sendable {
    let id: UUID
    let questionKey: String?
    let questionType: String  // single_choice, multiple_choice, text, number, scale, slider, boolean, date, time, textarea
    let label: String
    let descriptionHtml: String?
    let placeholder: String?
    let isRequired: Bool?
    let sortOrder: Int?
    let validationRules: AnyCodableValue?
    let displayRules: AnyCodableValue?
    let metadata: AnyCodableValue?
    let options: [QuestionOption]?

    var required: Bool {
        isRequired ?? false
    }
}

struct QuestionOption: Codable, Identifiable, Sendable {
    let id: UUID
    let questionId: UUID?
    let label: String
    let value: String?
    let score: AnyCodableValue?
    let sortOrder: Int?
}

// MARK: - Questionnaire Submission

struct QuestionnaireSubmission: Codable, Sendable {
    let questionnaireVersionId: UUID
    let answers: [QuestionAnswer]
}

struct QuestionAnswer: Codable, Sendable {
    let questionId: UUID
    let answerValue: String?
    let selectedOptionIds: [UUID]?
}

struct QuestionnaireSubmissionResponse: Codable, Sendable {
    let id: UUID?
    let totalScore: Int?
    let riskLevel: String?
    let message: String?
}
