import Foundation

class CheckinService {
    private let networkManager = NetworkManager.shared

    /// Fetch a check-in template with its fields
    func fetchCheckinTemplate(templateId: String) async throws -> CheckinTemplate {
        return try await networkManager.get("/api/patient/checkins/\(templateId)")
    }

    /// Submit check-in values
    func submitCheckin(
        templateId: String,
        values: [[String: String]]
    ) async throws -> CheckinSubmissionResponse {
        let body: [String: Any] = [
            "checkinTemplateId": templateId,
            "values": values
        ]

        return try await networkManager.post(
            "/api/patient/checkins/\(templateId)/submit",
            body: body
        )
    }
}
