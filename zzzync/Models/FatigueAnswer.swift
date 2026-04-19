import Foundation

struct FatigueAnswer: Codable {
    let generatedAt: Date
    let question: String
    let summary: String
    let causes: [FatigueCause]
    let actions: [String]
}

struct FatigueCause: Codable, Identifiable {
    let id: UUID
    let title: String
    let evidence: String
    let impactScore: Int   // 0...100

    init(id: UUID = UUID(), title: String, evidence: String, impactScore: Int) {
        self.id = id
        self.title = title
        self.evidence = evidence
        self.impactScore = max(0, min(100, impactScore))
    }
}
