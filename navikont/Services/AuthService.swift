import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isTestModeEnabled: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let networkManager = NetworkManager.shared

    init() {
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            networkManager.setToken(token)
            self.isAuthenticated = true
            
            if let userData = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
            }
            
            // Send APNs Token if exists
            if let deviceToken = UserDefaults.standard.string(forKey: "APNsDeviceToken") {
                Task {
                    try? await networkManager.sendDeviceToken(deviceToken)
                }
            }
        }
    }

    /// Login with email and password via the real backend API
    func login(username: String, password: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let body: [String: Any] = [
                    "email": username,
                    "password": password
                ]

                let response: LoginResponse = try await networkManager.post("/api/auth/login", body: body)

                await MainActor.run {
                    self.networkManager.setToken(response.token)
                    UserDefaults.standard.set(response.token, forKey: "authToken")
                    
                    if let encodedUser = try? JSONEncoder().encode(response.user) {
                        UserDefaults.standard.set(encodedUser, forKey: "currentUser")
                    }
                    
                    self.currentUser = response.user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
                
                // Send APNs Token if exists
                if let token = UserDefaults.standard.string(forKey: "APNsDeviceToken") {
                    try? await self.networkManager.sendDeviceToken(token)
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    self.errorMessage = error.errorDescription
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Giriş başarısız: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func logout() {
        networkManager.clearToken()
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        self.currentUser = nil
        self.isAuthenticated = false
        self.errorMessage = nil
    }
    
    func changePassword(oldPassword: String, newPassword: String) async throws -> String {
        let body: [String: Any] = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
        ]
        
        let response: SuccessResponse = try await networkManager.post("/api/auth/change-password", body: body)
        return response.message ?? "Başarılı"
    }
    
    func uploadProfileImage(base64String: String) async throws {
        let body: [String: Any] = [
            "profileImage": base64String
        ]
        
        struct ProfileImageResponse: Decodable {
            let success: Bool
            let profileImage: String
        }
        
        let response: ProfileImageResponse = try await networkManager.post("/api/patient/profile-image", body: body)
        
        await MainActor.run {
            if let current = self.currentUser {
                let updatedUser = User(
                    id: current.id,
                    email: current.email,
                    phone: current.phone,
                    fullName: current.fullName,
                    userType: current.userType,
                    status: current.status,
                    profileImage: response.profileImage
                )
                self.currentUser = updatedUser
                
                if let encodedUser = try? JSONEncoder().encode(updatedUser) {
                    UserDefaults.standard.set(encodedUser, forKey: "currentUser")
                }
            }
        }
    }
}

struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
}
