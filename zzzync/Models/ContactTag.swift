import Foundation

enum ContactPriority: String, Codable, CaseIterable {
    case high
    case low

    var label: String {
        switch self {
        case .high: return "High"
        case .low: return "Low"
        }
    }
}

struct ContactTag: Codable, Identifiable {
    let id: UUID
    let email: String
    let priority: ContactPriority
    let createdAt: Date?
    let updatedAt: Date?

    init(
        id: UUID = UUID(),
        email: String,
        priority: ContactPriority,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email.lowercased()
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
