import Foundation

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String?)
    case unauthorized
    case networkFailure(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .noData:
            return "Sunucudan veri alınamadı"
        case .decodingError(let error):
            return "Veri işleme hatası: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return message ?? "Sunucu hatası (\(code))"
        case .unauthorized:
            return "Oturum süresi doldu. Lütfen tekrar giriş yapın."
        case .networkFailure(let error):
            return "Bağlantı hatası: \(error.localizedDescription)"
        case .unknown:
            return "Bilinmeyen bir hata oluştu"
        }
    }
}

// MARK: - API Response Wrappers

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct EmptyResponse: Decodable {}

// MARK: - Network Manager

final class NetworkManager: @unchecked Sendable {
    static let shared = NetworkManager()

    // "localhost" emülatörde Mac'i temsil ederken, gerçek cihazda telefonun kendisini temsil ettiği için bağlantı hatası verir.
    // Mac'inizin Wi-Fi ağındaki yerel IP'si yerine gerçek Railway sunucu adresinizi giriyoruz:
    var baseURL: String = "https://navikont-app-backend-production.up.railway.app"
    private var token: String?

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO 8601 with fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try ISO 8601 without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try date-only format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
    }

    // MARK: - Token Management

    func setToken(_ token: String?) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }

    var isAuthenticated: Bool {
        token != nil
    }

    // MARK: - Generic Request Methods

    func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try buildRequest(path: path, method: "GET")
        return try await execute(request)
    }

    func post<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        var request = try buildRequest(path: path, method: "POST")
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await execute(request)
    }

    func put<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        var request = try buildRequest(path: path, method: "PUT")
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await execute(request)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let request = try buildRequest(path: path, method: "DELETE")
        return try await execute(request)
    }

    // Fire-and-forget POST (returns Void)
    func postVoid(_ path: String, body: [String: Any]? = nil) async throws {
        var request = try buildRequest(path: path, method: "POST")
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMsg = message?["error"] as? String ?? message?["message"] as? String
            
            if httpResponse.statusCode == 401 {
                if let errorMsg = errorMsg, !errorMsg.isEmpty {
                    throw NetworkError.serverError(401, errorMsg)
                } else {
                    throw NetworkError.unauthorized
                }
            }
            throw NetworkError.serverError(httpResponse.statusCode, errorMsg)
        }
    }
    
    func sendDeviceToken(_ token: String) async throws {
        let body: [String: Any] = [
            "deviceToken": token,
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        try await postVoid("/api/patient/device-token", body: body)
    }

    // MARK: - Private Helpers

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.networkFailure(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMsg = errorBody?["error"] as? String ?? errorBody?["message"] as? String
            
            if httpResponse.statusCode == 401 {
                if let errorMsg = errorMsg, !errorMsg.isEmpty {
                    throw NetworkError.serverError(401, errorMsg)
                } else {
                    throw NetworkError.unauthorized
                }
            }
            throw NetworkError.serverError(httpResponse.statusCode, errorMsg)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("⚠️ Decoding error for \(T.self): \(error)")
                print("⚠️ Raw JSON: \(jsonString.prefix(1000))")
            }
            #endif
            throw NetworkError.decodingError(error)
        }
    }
}
