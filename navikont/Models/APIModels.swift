import Foundation

// MARK: - Dashboard Response (from /api/patient/dashboard)
// Backend returns: { enrollment: {...}, today: { tasks: [...] }, progress: {...}, streak: {...} }

struct DashboardResponse: Decodable, Sendable {
    let enrollment: BackendEnrollment
    let today: TodayPayload?
    let progress: ProgressPayload?
    let streak: StreakPayload?

    var streakCount: Int { streak?.currentStreak ?? 0 }
    var todayTasks: [JourneyStep]? { today?.tasks }

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
}
