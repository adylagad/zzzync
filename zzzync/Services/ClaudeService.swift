import Foundation
import UIKit

final class ClaudeService {
    static let shared = ClaudeService()

    private var apiKey: String { UserDefaults.standard.string(forKey: "claudeAPIKey") ?? "" }
    private let endpoint = URL(string: Constants.claudeAPIEndpoint)!
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private init() {}

    // MARK: - Social Jetlag

    func analyzeSocialJetlag(
        sleepRecords: [SleepRecord],
        calendarEvents: [CalendarEvent]
    ) async throws -> SocialJetlagResult {
        let midpoints = sleepRecords.map { $0.midpoint }
        let avgMidpoint = midpoints.average() ?? Date()

        let firstEvents = calendarEvents.sorted { $0.startDate < $1.startDate }
        let firstEventTimes = Dictionary(grouping: calendarEvents) {
            Calendar.current.startOfDay(for: $0.startDate)
        }.compactMapValues { events in
            events.filter { !$0.isAllDay }.sorted { $0.startDate < $1.startDate }.first?.startDate
        }.values
        let avgFirstEvent = Array(firstEventTimes).average() ?? Date()

        let sleepSummary = sleepRecords.map { r in
            "Date: \(r.date.shortDateString), bedtime: \(r.bedtime.timeString), wake: \(r.wakeTime.timeString), midpoint: \(r.midpoint.timeString)"
        }.joined(separator: "\n")

        let eventSummary = calendarEvents.prefix(20).map { e in
            "\(e.startDate.shortDateString) \(e.startDate.timeString): \(e.title)"
        }.joined(separator: "\n")

        let prompt = """
        Analyze the following 7-day sleep and calendar data and calculate Social Jetlag.

        SLEEP MIDPOINTS (last 7 days):
        \(sleepSummary)

        FIRST CALENDAR EVENTS (last 7 days):
        \(eventSummary)

        Average sleep midpoint: \(avgMidpoint.timeString)
        Average first event: \(avgFirstEvent.timeString)

        Respond with JSON matching this schema:
        \(SystemPrompts.socialJetlagSchema)
        """

        let raw = try await sendMessage(prompt: prompt)
        let parsed = try parseJSON(raw, as: SocialJetlagRaw.self)

        return SocialJetlagResult(
            generatedAt: Date(),
            averageMidpoint: avgMidpoint,
            firstEventAverage: avgFirstEvent,
            jetlagHours: parsed.jetlag_hours,
            chronotypeDrift: parsed.chronotype_drift,
            claudeNarrative: parsed.claude_narrative,
            score: parsed.score
        )
    }

    // MARK: - Metabolic Audit

    func auditFoodLog(
        foodLog: FoodLog,
        recentBiometrics: [BiometricRecord],
        imageBase64: String? = nil
    ) async throws -> MetabolicAuditResult {
        let biometricsText = recentBiometrics.suffix(3).map { b in
            "\(b.date.shortDateString): HRV \(b.hrvMs.map { String(format: "%.0f ms", $0) } ?? "N/A"), RHR \(b.rhrBpm.map { String(format: "%.0f bpm", $0) } ?? "N/A")"
        }.joined(separator: "\n")

        let textContent: [String: Any] = [
            "type": "text",
            "text": """
            Audit this food log entry for metabolic timing.

            Meal logged at: \(foodLog.timestamp.timeString) on \(foodLog.timestamp.shortDateString)
            Description: \(foodLog.description)

            Recent biometrics (last 3 days):
            \(biometricsText)

            Respond with JSON matching this schema:
            \(SystemPrompts.metabolicAuditSchema)
            """
        ]

        var content: [[String: Any]] = []
        if let base64 = imageBase64 {
            content.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": base64
                ]
            ])
        }
        content.append(textContent)

        let raw = try await sendMessage(contentBlocks: content)
        let parsed = try parseJSON(raw, as: MetabolicAuditRaw.self)

        let verdict: MetabolicAuditResult.TimingVerdict
        switch parsed.timing_verdict {
        case "on_clock":   verdict = .onClock
        case "borderline": verdict = .borderline
        default:           verdict = .offClock
        }

        return MetabolicAuditResult(
            mealDescription: parsed.meal_description,
            timingVerdict: verdict,
            hoursFromDigestiveSunset: parsed.hours_from_digestive_sunset,
            metabolicInsight: parsed.metabolic_insight,
            claudeNarrative: parsed.claude_narrative
        )
    }

    // MARK: - Energy Forecast

    func generateEnergyForecast(
        todayEvents: [CalendarEvent],
        biometrics: [BiometricRecord],
        sleepLastNight: SleepRecord?
    ) async throws -> EnergyForecast {
        let eventText = todayEvents.map { e in
            "\(e.startDate.timeString)–\(e.endDate.timeString): \(e.title) (stress weight: \(e.stressWeight))"
        }.joined(separator: "\n")

        let sleepText = sleepLastNight.map { s in
            "Last night: bed \(s.bedtime.timeString), wake \(s.wakeTime.timeString), \(s.durationMinutes) min total"
        } ?? "No sleep data available"

        let bioText = biometrics.suffix(3).map { b in
            "\(b.date.shortDateString): HRV \(b.hrvMs.map { String(format: "%.0fms", $0) } ?? "N/A"), RHR \(b.rhrBpm.map { String(format: "%.0fbpm", $0) } ?? "N/A")"
        }.joined(separator: "\n")

        let prompt = """
        Generate a circadian energy forecast for today based on this data.

        TODAY'S CALENDAR:
        \(eventText.isEmpty ? "No events scheduled" : eventText)

        LAST NIGHT'S SLEEP:
        \(sleepText)

        RECENT BIOMETRICS:
        \(bioText)

        Today's date: \(Date().shortDateString)

        Identify any Cognitive Clashes (important meetings scheduled during predicted low-energy windows).
        Respond with JSON matching this schema:
        \(SystemPrompts.energyForecastSchema)
        """

        let raw = try await sendMessage(prompt: prompt)
        let parsed = try parseJSON(raw, as: EnergyForecastRaw.self)

        let clashes = try parsed.cognitive_clashes.map { clash -> CognitiveClash in
            guard let start = isoFormatter.date(from: clash.event_start_iso) else {
                throw ClaudeServiceError.dateParsingFailed(clash.event_start_iso)
            }
            let severity: ClashSeverity = {
                switch clash.severity {
                case "high": return .high
                case "low":  return .low
                default:     return .medium
                }
            }()
            return CognitiveClash(
                eventTitle: clash.event_title,
                eventStart: start,
                predictedEnergyLevel: clash.predicted_energy_level,
                severity: severity,
                suggestion: clash.suggestion
            )
        }

        let hourlyMap = Dictionary(uniqueKeysWithValues:
            parsed.hourly_energy_level.compactMap { k, v -> (Int, Double)? in
                guard let hour = Int(k) else { return nil }
                return (hour, v)
            }
        )

        return EnergyForecast(
            date: Date(),
            hourlyEnergyLevel: hourlyMap,
            cognitiveClashes: clashes,
            claudeNarrative: parsed.claude_narrative
        )
    }

    // MARK: - Bio Protocol

    func generateBioProtocol(
        jetlagResult: SocialJetlagResult,
        forecast: EnergyForecast?,
        recentFoodLogs: [FoodLog]
    ) async throws -> BioProtocol {
        let foodText = recentFoodLogs.suffix(5).map { log in
            "\(log.timestamp.timeString): \(log.description)"
        }.joined(separator: "\n")

        let prompt = """
        Generate a personalized Bio-Protocol (optimized 24-hour schedule) for today.

        SOCIAL JETLAG SUMMARY:
        Score: \(jetlagResult.score)/100
        Jetlag: \(String(format: "%.1f", jetlagResult.jetlagHours)) hours
        \(jetlagResult.chronotypeDrift)

        RECENT FOOD LOGS (last 5 meals):
        \(foodText.isEmpty ? "No food logs available" : foodText)

        Today's date: \(Date().shortDateString)

        Generate specific times for:
        - First safe caffeine window (after cortisol peak)
        - Peak cognitive work window
        - Meals timed to biological digestive clock
        - Rest/recovery recommendations

        Respond with JSON matching this schema:
        \(SystemPrompts.bioProtocolSchema)
        """

        let raw = try await sendMessage(prompt: prompt)
        let parsed = try parseJSON(raw, as: BioProtocolRaw.self)

        func parseDate(_ str: String) throws -> Date {
            if let d = isoFormatter.date(from: str) { return d }
            throw ClaudeServiceError.dateParsingFailed(str)
        }

        let items = try parsed.protocol_items.map { item -> ProtocolItem in
            let time = try parseDate(item.time_iso)
            let cat: ProtocolCategory = ProtocolCategory(rawValue: item.category) ?? .cognitiveWork
            return ProtocolItem(time: time, category: cat, title: item.title, rationale: item.rationale)
        }

        return BioProtocol(
            date: Date(),
            caffeineWindowStart: try parseDate(parsed.caffeine_window_start_iso),
            peakBrainWindowStart: try parseDate(parsed.peak_brain_window_start_iso),
            peakBrainWindowEnd: try parseDate(parsed.peak_brain_window_end_iso),
            digestiveSunset: try parseDate(parsed.digestive_sunset_iso),
            protocolItems: items.sorted { $0.time < $1.time },
            claudeNarrative: parsed.claude_narrative
        )
    }

    // MARK: - Core API call

    private func sendMessage(prompt: String) async throws -> String {
        let content: [[String: Any]] = [["type": "text", "text": prompt]]
        return try await sendMessage(contentBlocks: content)
    }

    private func sendMessage(contentBlocks: [[String: Any]]) async throws -> String {
        guard !apiKey.isEmpty else { throw ClaudeServiceError.noAPIKey }

        let body: [String: Any] = [
            "model": Constants.claudeModel,
            "max_tokens": Constants.claudeMaxTokens,
            "system": SystemPrompts.chronobiologist,
            "messages": [
                ["role": "user", "content": contentBlocks]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeServiceError.apiError(msg)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw ClaudeServiceError.malformedResponse
        }

        return text
    }

    private func parseJSON<T: Decodable>(_ text: String, as type: T.Type) throws -> T {
        // Strip markdown fences if Claude includes them despite instructions
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```") {
            clean = clean.components(separatedBy: "\n").dropFirst().dropLast().joined(separator: "\n")
        }
        guard let data = clean.data(using: .utf8) else { throw ClaudeServiceError.malformedResponse }
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Raw response types (match Claude's JSON schema)

private struct SocialJetlagRaw: Decodable {
    let score: Int
    let jetlag_hours: Double
    let chronotype_drift: String
    let claude_narrative: String
}

private struct MetabolicAuditRaw: Decodable {
    let meal_description: String
    let timing_verdict: String
    let hours_from_digestive_sunset: Double
    let metabolic_insight: String
    let claude_narrative: String
}

private struct EnergyForecastRaw: Decodable {
    let hourly_energy_level: [String: Double]   // JSON keys are strings; convert to Int on use
    let cognitive_clashes: [CognitiveClashRaw]
    let claude_narrative: String

    struct CognitiveClashRaw: Decodable {
        let event_title: String
        let event_start_iso: String
        let predicted_energy_level: Double
        let severity: String
        let suggestion: String
    }
}

private struct BioProtocolRaw: Decodable {
    let caffeine_window_start_iso: String
    let peak_brain_window_start_iso: String
    let peak_brain_window_end_iso: String
    let digestive_sunset_iso: String
    let protocol_items: [ProtocolItemRaw]
    let claude_narrative: String

    struct ProtocolItemRaw: Decodable {
        let time_iso: String
        let category: String
        let title: String
        let rationale: String
    }
}

enum ClaudeServiceError: LocalizedError {
    case noAPIKey
    case apiError(String)
    case malformedResponse
    case dateParsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:                    return "No Claude API key set. Add it in Settings."
        case .apiError(let msg):           return "API error: \(msg)"
        case .malformedResponse:           return "Claude returned an unexpected response format."
        case .dateParsingFailed(let str):  return "Could not parse date: \(str)"
        }
    }
}
