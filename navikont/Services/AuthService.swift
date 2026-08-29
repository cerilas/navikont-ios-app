import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var currentProfile: PatientProfile?
    @Published var isAuthenticated: Bool = false
    @Published var isTestModeEnabled: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let networkManager = NetworkManager.shared

    private var sessionObserver: NSObjectProtocol?

    init() {
        // Listen for 401 session expired from NetworkManager
        sessionObserver = NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.isAuthenticated else { return }
            self.logout()
            self.errorMessage = "Oturumunuzun süresi doldu. Güvenliğiniz için yeniden giriş yapmanız gerekmektedir."
        }

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            networkManager.setToken(token)
            self.isAuthenticated = true
            
            if let userData = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
            }
            if let profileData = UserDefaults.standard.data(forKey: "currentProfile"),
               let profile = try? JSONDecoder().decode(PatientProfile.self, from: profileData) {
                self.currentProfile = profile
            }
            
            // Send APNs Token if exists
            if let deviceToken = UserDefaults.standard.string(forKey: "APNsDeviceToken") {
                Task {
                    try? await networkManager.sendDeviceToken(deviceToken)
                }
            }
        }
    }

    deinit {
        if let observer = sessionObserver {
            NotificationCenter.default.removeObserver(observer)
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
                    if let profile = response.profile, let encodedProfile = try? JSONEncoder().encode(profile) {
                        UserDefaults.standard.set(encodedProfile, forKey: "currentProfile")
                    }
                    
                    self.currentUser = response.user
                    self.currentProfile = response.profile
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
                    self.errorMessage = AppStrings.t("Giriş başarısız") + ": \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func logout() {
        ClinicalOfflineStore.shared.deactivate()
        networkManager.clearToken()
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "currentProfile")
        self.currentUser = nil
        self.currentProfile = nil
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
    
    struct ProfileUpdateResponse: Decodable {
        let success: Bool
        let profile: PatientProfile
    }
    
    func updateProfile(birthDate: String?, gender: String?, heightCm: Double?, weightKg: Double?, bloodType: String?, diseaseIds: [String]?) async throws {
        let body: [String: Any?] = [
            "birth_date": birthDate,
            "gender": gender,
            "height_cm": heightCm,
            "weight_kg": weightKg,
            "blood_type": bloodType,
            "disease_ids": diseaseIds
        ]
        
        let filteredBody = body.compactMapValues { $0 }
        
        let response: ProfileUpdateResponse = try await networkManager.post("/api/patient/profile", body: filteredBody)
        
        await MainActor.run {
            self.currentProfile = response.profile
            if let encodedProfile = try? JSONEncoder().encode(response.profile) {
                UserDefaults.standard.set(encodedProfile, forKey: "currentProfile")
            }
        }
    }
    
    func fetchDiseases() async throws -> [Disease] {
        return try await networkManager.get("/api/diseases")
    }
    
    func fetchMe() async throws {
        let response: PatientMeResponse = try await networkManager.get("/api/patient/me")
        await MainActor.run {
            self.currentUser = response.user
            self.currentProfile = response.profile
            
            if let encodedUser = try? JSONEncoder().encode(response.user) {
                UserDefaults.standard.set(encodedUser, forKey: "currentUser")
            }
            if let profile = response.profile, let encodedProfile = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(encodedProfile, forKey: "currentProfile")
            }
        }
    }
}

struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
}
