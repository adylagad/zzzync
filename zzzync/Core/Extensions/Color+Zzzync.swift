import SwiftUI

extension Color {
    // Brand palette — deep indigo night sky meets soft amber dawn
    static let zzzyncPrimary      = Color(red: 0.40, green: 0.32, blue: 0.86)   // indigo
    static let zzzyncAccent       = Color(red: 1.00, green: 0.72, blue: 0.30)   // amber
    static let zzzyncBackground   = Color(red: 0.06, green: 0.06, blue: 0.14)   // near-black
    static let zzzyncSurface      = Color(red: 0.11, green: 0.11, blue: 0.22)   // dark card
    static let zzzyncMuted        = Color(red: 0.55, green: 0.55, blue: 0.70)   // soft gray

    // Score colors
    static let zzzyncScoreGood    = Color(red: 0.25, green: 0.85, blue: 0.55)   // green
    static let zzzyncScoreWarn    = Color(red: 1.00, green: 0.80, blue: 0.20)   // yellow
    static let zzzyncScoreBad     = Color(red: 0.95, green: 0.35, blue: 0.35)   // red

    static func syncScoreColor(score: Int) -> Color {
        switch score {
        case 70...100: return .zzzyncScoreGood
        case 40..<70:  return .zzzyncScoreWarn
        default:       return .zzzyncScoreBad
        }
    }
}
