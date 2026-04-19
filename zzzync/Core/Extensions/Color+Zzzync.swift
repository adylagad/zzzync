import SwiftUI

extension Color {
    // Backgrounds — true black like Apple Health dark mode
    static let zzzyncBackground  = Color.black
    static let zzzyncSurface     = Color(red: 0.11, green: 0.11, blue: 0.12)   // #1C1C1E
    static let zzzyncSurface2    = Color(red: 0.17, green: 0.17, blue: 0.18)   // #2C2C2E
    static let zzzyncMuted       = Color(white: 0.50)
    static let zzzyncSubtle      = Color(white: 0.30)

    // Accent palette — each maps to a health domain like Apple Health rings
    static let zzzyncPrimary     = Color(red: 0.53, green: 0.44, blue: 0.93)   // sleep purple
    static let zzzyncBlue        = Color(red: 0.20, green: 0.67, blue: 1.00)   // HRV / energy blue
    static let zzzyncGreen       = Color(red: 0.24, green: 0.93, blue: 0.45)   // metabolic green
    static let zzzyncAccent      = Color(red: 1.00, green: 0.62, blue: 0.00)   // protocol amber
    static let zzzyncRed         = Color(red: 1.00, green: 0.27, blue: 0.23)   // warning red
    static let zzzyncTeal        = Color(red: 0.18, green: 0.83, blue: 0.78)   // recovery teal

    // Score → color mapping
    static let zzzyncScoreGood   = Color(red: 0.24, green: 0.93, blue: 0.45)
    static let zzzyncScoreWarn   = Color(red: 1.00, green: 0.80, blue: 0.20)
    static let zzzyncScoreBad    = Color(red: 1.00, green: 0.27, blue: 0.23)

    static func syncScoreColor(score: Int) -> Color {
        switch score {
        case 70...100: return .zzzyncScoreGood
        case 40..<70:  return .zzzyncScoreWarn
        default:       return .zzzyncScoreBad
        }
    }
}
