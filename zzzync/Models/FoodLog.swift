import Foundation

struct FoodLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let description: String         // user text or Claude-extracted from photo
    let imageData: Data?            // JPEG stored locally
    var auditResult: MetabolicAuditResult?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        description: String,
        imageData: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.description = description
        self.imageData = imageData
    }
}
