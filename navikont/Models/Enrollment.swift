import Foundation

struct Enrollment: Codable, Identifiable, Sendable {
    let id: UUID
    let patientUserId: UUID
    let doctorUserId: UUID?
    let appId: UUID
    let appVersionId: UUID?
    let journeyId: UUID?
    let status: String
    let startDate: Date?
    let currentDay: Int
    let progressPercent: Int
    let assignedAt: Date?
}
