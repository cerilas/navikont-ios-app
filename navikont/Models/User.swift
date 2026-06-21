import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let phone: String?
    let fullName: String
    let userType: String?
    let status: String?
    let profileImage: String?

    /// Convenience: returns first word of fullName as a display first name
    var firstName: String {
        let components = fullName.components(separatedBy: " ")
        return components.first ?? fullName
    }
}
