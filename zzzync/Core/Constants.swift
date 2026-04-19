import Foundation

enum Constants {
    static let claudeModel = "claude-sonnet-4-6"
    static let claudeAPIEndpoint = "https://api.anthropic.com/v1/messages"
    static let claudeMaxTokens = 2048

    // Sleep session grouping: samples within this interval belong to the same session
    static let sleepSessionGapSeconds: TimeInterval = 30 * 60

    // Analysis window
    static let sleepLookbackDays = 7
    static let biometricLookbackDays = 7

    // Food photo quality for Claude Vision (keeps size under 1MB)
    static let foodPhotoJPEGQuality: CGFloat = 0.7
}
