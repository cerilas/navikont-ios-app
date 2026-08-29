import Foundation

final class ClinicalService {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }

    func fetchClinicalState() async throws -> ClinicalStateResponse {
        try await networkManager.get("/api/patient/clinical-state")
    }

    func completeAsset(contentId: String, payload: AssetCompletionPayload) async throws -> AssetCompletionResponse {
        try await networkManager.post(
            "/api/patient/clinical/assets/\(escaped(contentId))/complete",
            body: try dictionary(payload)
        )
    }

    func fetchCurrentDiarySession() async throws -> BladderDiarySession? {
        do {
            return try await networkManager.get("/api/patient/m2/sessions/current")
        } catch NetworkError.serverError(let status, let message)
            where status == 404 || message?.localizedCaseInsensitiveContains("SESSION_NOT_FOUND") == true {
            return nil
        }
    }

    func startDiarySession() async throws -> BladderDiarySession {
        try await networkManager.post(
            "/api/patient/m2/sessions/current",
            body: ["idempotencyKey": UUID().uuidString]
        )
    }

    func createDiaryEvent(_ event: BladderDiaryEvent) async throws -> BladderDiaryEvent {
        var body = try dictionary(event)
        body["idempotencyKey"] = event.id.uuidString
        body["eventId"] = event.id.uuidString
        return try await networkManager.post("/api/patient/m2/events", body: body)
    }

    func mutateDiaryEvent(id: UUID, mutation: BladderDiaryEventMutation) async throws -> BladderDiaryEvent {
        try await networkManager.patch(
            "/api/patient/m2/events/\(id.uuidString)",
            body: try dictionary(mutation)
        )
    }

    func submitDiary(sessionId: UUID, testBypass: Bool = false) async throws -> BladderDiarySession {
        try await networkManager.post(
            "/api/patient/m2/submit",
            body: [
                "sessionId": sessionId.uuidString,
                "testBypass": testBypass,
            ]
        )
    }

    func fetchCurrentPlan() async throws -> ClinicalPlan {
        try await networkManager.get("/api/patient/plan/current")
    }

    func submitTeachBack(_ payload: TeachBackResponsePayload) async throws -> TeachBackEpisode {
        try await networkManager.post(
            "/api/patient/teachback/responses",
            body: try dictionary(payload)
        )
    }

    func fetchM5() async throws -> M5Payload {
        try await networkManager.get("/api/patient/m5/records")
    }

    func createM5Record(_ payload: M5RecordPayload) async throws -> M5Record {
        var body = try dictionary(payload)
        body["idempotencyKey"] = payload.id.uuidString
        return try await networkManager.post("/api/patient/m5/records", body: body)
    }

    func fetchM6() async throws -> M6Payload {
        try await networkManager.get("/api/patient/m6/current")
    }

    func fetchM7() async throws -> M7Payload {
        try await networkManager.get("/api/patient/m7/current")
    }

    func fetchM8() async throws -> M8Payload {
        try await networkManager.get("/api/patient/m8/current")
    }

    private func escaped(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }

    private func dictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.unknown
        }
        return object
    }
}
