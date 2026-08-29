import Foundation

// MARK: - Dashboard Response (from /api/patient/dashboard)
// Backend returns: { enrollment: {...}, today: { tasks: [...] }, progress: {...}, streak: {...} }

struct DashboardResponse: Decodable, Sendable {
    let enrollment: BackendEnrollment
    let today: TodayPayload?
    let progress: ProgressPayload?
    let streak: StreakPayload?
    let unreadNotificationCount: Int?
    let clinicalState: PatientClinicalState?
    let gates: [ClinicalGate]?
    let activePlanSummary: ActivePlanSummary?

    var streakCount: Int { streak?.currentStreak ?? 0 }
    var todayTasks: [JourneyStep]? { today?.tasks }
    var unreadNotifications: Int { unreadNotificationCount ?? 0 }

    var mappedEnrollment: Enrollment {
        Enrollment(
            id: enrollment.id,
            patientUserId: enrollment.patientUserId ?? UUID(),
            doctorUserId: nil,
            appId: enrollment.appId ?? UUID(),
            appVersionId: enrollment.appVersionId,
            journeyId: enrollment.journeyId,
            status: enrollment.status ?? "active",
            startDate: enrollment.startDate,
            currentDay: enrollment.currentDay ?? 1,
            progressPercent: Int(enrollment.progressPercent ?? "0") ?? 0,
            assignedAt: enrollment.activatedAt
        )
    }
}

struct BackendEnrollment: Decodable, Sendable {
    let id: UUID
    let patientUserId: UUID?
    let doctorUserId: UUID?
    let appId: UUID?
    let appVersionId: UUID?
    let journeyId: UUID?
    let status: String?
    let startDate: Date?
    let endDate: Date?
    let currentDay: Int?
    let progressPercent: String?
    let activatedAt: Date?
    let assignedAt: Date?
}

struct TodayPayload: Decodable, Sendable {
    let currentDay: Int?
    let totalTasks: Int?
    let completedTasks: Int?
    let tasks: [JourneyStep]?
}

struct ProgressPayload: Decodable, Sendable {
    let totalSteps: Int?
    let completedModules: Int?
    let progressPercent: Int?
}

struct StreakPayload: Decodable, Sendable {
    let currentStreak: Int?
    let longestStreak: Int?
    let lastCompletedDate: String?
    let freezeCount: Int?

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastCompletedDate = "last_completed_date"
        case freezeCount = "freeze_count"
    }
}

// MARK: - Today Tasks Response (from /api/patient/today)

struct TodayTasksResponse: Decodable, Sendable {
    let currentDay: Int?
    let totalTasks: Int?
    let completedTasks: Int?
    let tasks: [JourneyStep]?
}

// MARK: - Module Complete Response

struct ModuleCompleteResponse: Codable, Sendable {
    let success: Bool?
    let message: String?
    let progressPercent: Int?
}

// MARK: - Login Response

struct LoginResponse: Decodable, Sendable {
    let token: String
    let user: User
    let profile: PatientProfile?
}

struct PatientMeResponse: Decodable, Sendable {
    let user: User
    let profile: PatientProfile?
}

struct PatientProfile: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let birthDate: String?
    let gender: String?
    let heightCm: Double?
    let weightKg: Double?
    let bloodType: String?
    let diseaseIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case birthDate = "birth_date"
        case gender
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case bloodType = "blood_type"
        case diseaseIds = "disease_ids"
    }
}

struct Disease: Codable, Identifiable, Sendable {
    let id: String
    let name: String
}

// MARK: - FAQs
struct FAQ: Codable, Identifiable, Sendable {
    let id: UUID
    let question: String
    let answer: String
    let orderIndex: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case answer
        case orderIndex = "order_index"
    }
}
