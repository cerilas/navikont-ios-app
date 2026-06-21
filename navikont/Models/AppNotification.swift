import Foundation

struct AppNotification: Codable, Identifiable {
    let id: UUID
    let title: String
    let body: String
    let createdAt: Date
    let readAt: Date?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, status
        case createdAt = "created_at"
        case readAt = "read_at"
    }
}
