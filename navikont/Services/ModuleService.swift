import Foundation



class ModuleService {
    private let networkManager = NetworkManager.shared

    /// Submit module completion to backend
    func submitModuleProgress(enrollmentId: UUID, moduleVersionId: UUID, resultData: [String: Any]? = nil) async throws -> Bool {
        var body: [String: Any] = [
            "enrollmentId": enrollmentId.uuidString,
            "moduleVersionId": moduleVersionId.uuidString
        ]
        
        if let resultData = resultData {
            body["resultData"] = resultData
        }

        let response: ModuleCompleteResponse = try await networkManager.post(
            "/api/patient/modules/\(moduleVersionId.uuidString)/complete",
            body: body
        )
        return response.success ?? true
    }
}
