import SwiftUI

extension Color {
    // Core dark palette
    static let zzzyncBackground  = Color.black
    static let zzzyncSurface     = Color(red: 0.10, green: 0.11, blue: 0.14)   // deep graphite
    static let zzzyncSurface2    = Color(red: 0.18, green: 0.20, blue: 0.24)   // divider / track
    static let zzzyncMuted       = Color(red: 0.55, green: 0.57, blue: 0.62)
    static let zzzyncSubtle      = Color(red: 0.34, green: 0.36, blue: 0.41)

    // Accent palette — dark + green theme with utility accents
    static let zzzyncPrimary     = Color(red: 0.64, green: 1.00, blue: 0.00)   // neon lime
    static let zzzyncBlue        = Color(red: 0.13, green: 0.78, blue: 1.00)   // cyan utility
    static let zzzyncGreen       = Color(red: 0.39, green: 0.89, blue: 0.17)   // supportive green
    static let zzzyncAccent      = Color(red: 0.98, green: 0.78, blue: 0.20)   // warm highlight
    static let zzzyncRed         = Color(red: 1.00, green: 0.34, blue: 0.34)   // warning red
    static let zzzyncTeal        = Color(red: 0.22, green: 0.85, blue: 0.72)   // recovery teal

    // Foreground tokens
    static let zzzyncOnPrimary   = Color.black

    // Score → color mapping
    static let zzzyncScoreGood   = Color(red: 0.39, green: 0.89, blue: 0.17)
    static let zzzyncScoreWarn   = Color(red: 1.00, green: 0.80, blue: 0.20)
    static let zzzyncScoreBad    = Color(red: 1.00, green: 0.34, blue: 0.34)

    static func syncScoreColor(score: Int) -> Color {
        switch score {
        case 70...100: return .zzzyncScoreGood
        case 40..<70:  return .zzzyncScoreWarn
        default:       return .zzzyncScoreBad
        }
    }
}
