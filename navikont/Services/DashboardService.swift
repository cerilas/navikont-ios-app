import Foundation

class DashboardService {
    private let networkManager = NetworkManager.shared

    /// Fetch combined dashboard data from backend
    func fetchDashboard() async throws -> DashboardResponse {
        return try await networkManager.get("/api/patient/dashboard")
    }

    /// Fetch today's tasks from backend
    func fetchTodayTasks() async throws -> [JourneyStep] {
        let response: TodayTasksResponse = try await networkManager.get("/api/patient/today")
        return response.tasks ?? []
    }

    /// Fetch active enrollment only
    func fetchActiveEnrollment() async throws -> Enrollment {
        return try await networkManager.get("/api/patient/enrollment")
    }

    /// Update current day for testing
    func updateCurrentDay(to day: Int) async throws -> Int {
        struct UpdateDayResponse: Codable {
            let success: Bool
            let currentDay: Int
        }
        let body = ["currentDay": day]
        let response: UpdateDayResponse = try await networkManager.put("/api/patient/enrollment/current-day", body: body)
        return response.currentDay
    }

    /// Fetch historical calendar progress
    func fetchCalendar() async throws -> CalendarResponse {
        return try await networkManager.get("/api/patient/dashboard/calendar")
    }
    
    func fetchCalendarDayDetails(date: String) async throws -> CalendarDayDetailsResponse {
        return try await networkManager.get("/api/patient/calendar/\(date)/tasks")
    }
}
