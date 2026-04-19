import Foundation

enum EmailProvider: String, Codable, CaseIterable {
    case gmail
    case outlook

    var label: String {
        switch self {
        case .gmail: return "Gmail"
        case .outlook: return "Outlook"
        }
    }
}

struct EmailStressSignal: Codable, Identifiable {
    let id: UUID
    let provider: EmailProvider
    let senderEmail: String
    let senderPriority: ContactPriority
    let unreadThreads: Int
    let threadLengthScore: Int
    let subjectKeywords: [String]
    let stressScore: Int
    let generatedAt: Date
}
