import Foundation

// MARK: - Patient Notification

struct PatientNotification: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String?
    let body: String?
    let notificationType: String?
    let isRead: Bool?
    let sentAt: Date?
    let readAt: Date?
}

// MARK: - Consent Document

struct ConsentDocument: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let content: String?
    let version: String?
    let isRequired: Bool?
    let documentType: String?
}
