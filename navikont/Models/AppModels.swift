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
    let code: String?
    let title: String
    let contentHtml: String?
    let versionNumber: Int?
    let documentType: String?
    let isRequired: Bool?
    let status: String?
    let publishedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case title
        case contentHtml = "content_html"
        case versionNumber = "version_number"
        case documentType = "document_type"
        case isRequired = "is_required"
        case status
        case publishedAt = "published_at"
    }
}
