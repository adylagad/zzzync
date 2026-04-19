import Foundation

struct EnergyForecast: Codable {
    let date: Date
    let hourlyEnergyLevel: [Int: Double]    // hour (0–23) → predicted level 0.0–1.0
    let cognitiveClashes: [CognitiveClash]
    let claudeNarrative: String
}

struct CognitiveClash: Codable, Identifiable {
    let id: UUID
    let eventTitle: String
    let eventStart: Date
    let predictedEnergyLevel: Double        // 0.0–1.0
    let severity: ClashSeverity
    let suggestion: String

    init(
        id: UUID = UUID(),
        eventTitle: String,
        eventStart: Date,
        predictedEnergyLevel: Double,
        severity: ClashSeverity,
        suggestion: String
    ) {
        self.id = id
        self.eventTitle = eventTitle
        self.eventStart = eventStart
        self.predictedEnergyLevel = predictedEnergyLevel
        self.severity = severity
        self.suggestion = suggestion
    }
}

enum ClashSeverity: String, Codable {
    case low, medium, high

    var color: String {
        switch self {
        case .low:    return "green"
        case .medium: return "yellow"
        case .high:   return "red"
        }
    }
}
