import Foundation

enum Constants {
    static let isHackathonDemoMode = true

    static let supabaseURL = "https://njjdonmeeumkrtvbyzmp.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qamRvbm1lZXVta3J0dmJ5em1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MTgzMDQsImV4cCI6MjA5MjE5NDMwNH0.i4jCPyxeohO5HJBnKkpjRe3zwJncUf7XPajD3e-4yr8"
    static let claudeEndpoint = "https://api.anthropic.com/v1/messages"
    static let emailStressSyncEndpoint = "\(supabaseURL)/functions/v1/email-stress-sync"
    static let claudeAPIKey = (Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    static let claudeModel = "claude-sonnet-4-6"
    static let claudeMaxTokens = 2048

    // Sleep session grouping: samples within this interval belong to the same session
    static let sleepSessionGapSeconds: TimeInterval = 30 * 60

    // Analysis window
    static let sleepLookbackDays = 7
    static let biometricLookbackDays = 7

    // Food photo quality for Claude Vision (keeps size under 1MB)
    static let foodPhotoJPEGQuality: CGFloat = 0.7
}
