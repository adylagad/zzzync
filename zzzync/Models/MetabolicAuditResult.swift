import Foundation

struct MetabolicAuditResult: Codable, Identifiable {
    let id: UUID
    let auditedAt: Date
    let mealDescription: String
    let timingVerdict: TimingVerdict    // on-clock, borderline, or off-clock
    let hoursFromDigestiveSunset: Double
    let metabolicInsight: String        // Claude's one-liner verdict
    let claudeNarrative: String         // full markdown explanation

    enum TimingVerdict: String, Codable {
        case onClock      = "on_clock"
        case borderline   = "borderline"
        case offClock     = "off_clock"

        var label: String {
            switch self {
            case .onClock:    return "On-Clock Eating"
            case .borderline: return "Borderline"
            case .offClock:   return "Off-Clock Eating"
            }
        }
    }

    init(
        id: UUID = UUID(),
        auditedAt: Date = Date(),
        mealDescription: String,
        timingVerdict: TimingVerdict,
        hoursFromDigestiveSunset: Double,
        metabolicInsight: String,
        claudeNarrative: String
    ) {
        self.id = id
        self.auditedAt = auditedAt
        self.mealDescription = mealDescription
        self.timingVerdict = timingVerdict
        self.hoursFromDigestiveSunset = hoursFromDigestiveSunset
        self.metabolicInsight = metabolicInsight
        self.claudeNarrative = claudeNarrative
    }
}
