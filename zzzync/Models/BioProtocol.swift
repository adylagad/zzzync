import Foundation

struct BioProtocol: Codable {
    let date: Date
    let caffeineWindowStart: Date
    let peakBrainWindowStart: Date
    let peakBrainWindowEnd: Date
    let digestiveSunset: Date
    let protocolItems: [ProtocolItem]
    let claudeNarrative: String
}

struct ProtocolItem: Codable, Identifiable {
    let id: UUID
    let time: Date
    let category: ProtocolCategory
    let title: String
    let rationale: String

    init(
        id: UUID = UUID(),
        time: Date,
        category: ProtocolCategory,
        title: String,
        rationale: String
    ) {
        self.id = id
        self.time = time
        self.category = category
        self.title = title
        self.rationale = rationale
    }
}

enum ProtocolCategory: String, Codable, CaseIterable {
    case caffeine       = "caffeine"
    case cognitiveWork  = "cognitive_work"
    case meal           = "meal"
    case rest           = "rest"
    case exercise       = "exercise"

    var systemImage: String {
        switch self {
        case .caffeine:      return "cup.and.saucer.fill"
        case .cognitiveWork: return "brain.head.profile"
        case .meal:          return "fork.knife"
        case .rest:          return "moon.zzz.fill"
        case .exercise:      return "figure.run"
        }
    }

    var label: String {
        switch self {
        case .caffeine:      return "Caffeine"
        case .cognitiveWork: return "Deep Work"
        case .meal:          return "Meal"
        case .rest:          return "Rest"
        case .exercise:      return "Exercise"
        }
    }
}
