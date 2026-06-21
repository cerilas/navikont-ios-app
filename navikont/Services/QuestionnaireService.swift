import Foundation

class QuestionnaireService {
    private let networkManager = NetworkManager.shared

    /// Fetch a questionnaire with its questions and options
    func fetchQuestionnaire(versionId: UUID) async throws -> QuestionnaireVersion {
        let wrapper: QuestionnaireResponseWrapper = try await networkManager.get("/api/patient/questionnaires/\(versionId.uuidString)")
        var version = wrapper.questionnaire
        if let questions = wrapper.questions {
            version.questions = questions
        }
        return version
    }

    /// Submit questionnaire answers
    func submitQuestionnaire(
        versionId: UUID,
        answers: [[String: Any]]
    ) async throws -> QuestionnaireSubmissionResponse {
        let body: [String: Any] = [
            "questionnaireVersionId": versionId.uuidString,
            "answers": answers
        ]

        return try await networkManager.post(
            "/api/patient/questionnaires/\(versionId.uuidString)/submit",
            body: body
        )
    }
}
