import Foundation

struct SocialJetlagResult: Codable {
    let generatedAt: Date
    let averageMidpoint: Date           // body's 7-day average sleep midpoint
    let firstEventAverage: Date         // average first calendar event start time
    let jetlagHours: Double             // headline number
    let chronotypeDrift: String         // timezone metaphor summary
    let claudeNarrative: String         // full markdown explanation
    let score: Int                      // 0–100 sync score

    var jetlagDescription: String {
        let h = abs(jetlagHours)
        let direction = jetlagHours > 0 ? "behind" : "ahead of"
        return String(format: "Your body is %.1f hour%@ %@ your calendar.", h, h == 1 ? "" : "s", direction)
    }
}
