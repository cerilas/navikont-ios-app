import Foundation

struct CalendarDay: Codable, Identifiable {
    var id: String { date }
    let dayNumber: Int
    let date: String // ISO 8601 string
    let status: DayStatus
    
    enum DayStatus: String, Codable {
        case completed
        case missed
        case current
        case future
    }
}

struct CalendarResponse: Codable {
    let enrollmentDate: String
    let currentDay: Int
    let totalDays: Int
    let days: [CalendarDay]
}

struct CalendarTaskDetail: Codable, Identifiable {
    let id: String
    let title: String
    let type: String
    let isRequired: Bool
    let isCompleted: Bool
    let completedAt: String?
    let originalDayNumber: Int
}

struct CalendarDayDetailsResponse: Codable {
    let date: String
    let targetDayNumber: Int
    let scheduledTasks: [CalendarTaskDetail]
    let extraCompletedTasks: [CalendarTaskDetail]
}
