import Foundation
import Supabase

// MARK: - Client

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://njjdonmeeumkrtvbyzmp.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qamRvbm1lZXVta3J0dmJ5em1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MTgzMDQsImV4cCI6MjA5MjE5NDMwNH0.i4jCPyxeohO5HJBnKkpjRe3zwJncUf7XPajD3e-4yr8"
        )
    }

    // MARK: - Auth

    /// Signs in anonymously. Creates an account on first call; restores session on subsequent calls.
    func signInAnonymously() async throws {
        // If there's already a session, nothing to do
        if let _ = try? await client.auth.session { return }
        try await client.auth.signInAnonymously()
    }

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    // MARK: - Sleep Records

    func upsertSleepRecords(_ records: [SleepRecord]) async throws {
        guard let userId = await currentUserId else { return }
        let rows = records.map { SleepRecordRow(from: $0, userId: userId) }
        try await client.from("sleep_records")
            .upsert(rows, onConflict: "id")
            .execute()
    }

    func fetchSleepRecords(days: Int = 7) async throws -> [SleepRecord] {
        guard let userId = await currentUserId else { return [] }
        let since = ISO8601DateFormatter().string(
            from: Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        )
        let rows: [SleepRecordRow] = try await client.from("sleep_records")
            .select()
            .eq("user_id", value: userId)
            .gte("date", value: since)
            .order("date", ascending: false)
            .execute()
            .value
        return rows.map { $0.toModel() }
    }

    // MARK: - Biometric Records

    func upsertBiometrics(_ records: [BiometricRecord]) async throws {
        guard let userId = await currentUserId else { return }
        let rows = records.map { BiometricRecordRow(from: $0, userId: userId) }
        try await client.from("biometric_records")
            .upsert(rows, onConflict: "user_id,date")
            .execute()
    }

    // MARK: - Food Logs

    func insertFoodLog(_ log: FoodLog) async throws {
        guard let userId = await currentUserId else { return }
        let row = FoodLogRow(from: log, userId: userId)
        try await client.from("food_logs")
            .insert(row)
            .execute()
    }

    func fetchFoodLogs(limit: Int = 20) async throws -> [FoodLog] {
        guard let userId = await currentUserId else { return [] }
        let rows: [FoodLogRow] = try await client.from("food_logs")
            .select()
            .eq("user_id", value: userId)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.map { $0.toModel() }
    }

    // MARK: - Social Jetlag Results

    func upsertJetlagResult(_ result: SocialJetlagResult) async throws {
        guard let userId = await currentUserId else { return }
        let row = JetlagResultRow(from: result, userId: userId)
        try await client.from("social_jetlag_results")
            .insert(row)
            .execute()
    }

    func fetchLatestJetlagResult() async throws -> SocialJetlagResult? {
        guard let userId = await currentUserId else { return nil }
        let rows: [JetlagResultRow] = try await client.from("social_jetlag_results")
            .select()
            .eq("user_id", value: userId)
            .order("generated_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first?.toModel()
    }

    // MARK: - Energy Forecasts

    func upsertEnergyForecast(_ forecast: EnergyForecast) async throws {
        guard let userId = await currentUserId else { return }
        let row = EnergyForecastRow(from: forecast, userId: userId)
        try await client.from("energy_forecasts")
            .upsert(row, onConflict: "user_id,date")
            .execute()
    }

    func fetchLatestEnergyForecast() async throws -> EnergyForecast? {
        guard let userId = await currentUserId else { return nil }
        let rows: [EnergyForecastRow] = try await client.from("energy_forecasts")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first?.toModel()
    }

    // MARK: - Bio Protocols

    func upsertBioProtocol(_ proto: BioProtocol) async throws {
        guard let userId = await currentUserId else { return }
        let row = BioProtocolRow(from: proto, userId: userId)
        try await client.from("bio_protocols")
            .upsert(row, onConflict: "user_id,date")
            .execute()
    }

    func fetchLatestBioProtocol() async throws -> BioProtocol? {
        guard let userId = await currentUserId else { return nil }
        let rows: [BioProtocolRow] = try await client.from("bio_protocols")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first?.toModel()
    }
}

// MARK: - Row types (Codable structs that map to DB columns)

private let iso = ISO8601DateFormatter()

struct SleepRecordRow: Codable {
    var id: UUID
    var user_id: UUID
    var date: String           // DATE as "YYYY-MM-DD"
    var bedtime: String        // TIMESTAMPTZ as ISO8601
    var wake_time: String
    var duration_minutes: Int
    var deep_sleep_minutes: Int
    var rem_sleep_minutes: Int

    init(from m: SleepRecord, userId: UUID) {
        id = m.id
        user_id = userId
        date = dateFormatter.string(from: m.date)
        bedtime = iso.string(from: m.bedtime)
        wake_time = iso.string(from: m.wakeTime)
        duration_minutes = m.durationMinutes
        deep_sleep_minutes = m.deepSleepMinutes
        rem_sleep_minutes = m.remSleepMinutes
    }

    func toModel() -> SleepRecord {
        SleepRecord(
            id: id,
            date: dateFormatter.date(from: date) ?? Date(),
            bedtime: iso.date(from: bedtime) ?? Date(),
            wakeTime: iso.date(from: wake_time) ?? Date(),
            durationMinutes: duration_minutes,
            deepSleepMinutes: deep_sleep_minutes,
            remSleepMinutes: rem_sleep_minutes
        )
    }
}

struct BiometricRecordRow: Codable {
    var id: UUID
    var user_id: UUID
    var date: String
    var hrv_ms: Double?
    var rhr_bpm: Double?
    var active_energy_kcal: Double?

    init(from m: BiometricRecord, userId: UUID) {
        id = m.id
        user_id = userId
        date = dateFormatter.string(from: m.date)
        hrv_ms = m.hrvMs
        rhr_bpm = m.rhrBpm
        active_energy_kcal = m.activeEnergyKcal
    }
}

struct FoodLogRow: Codable {
    var id: UUID
    var user_id: UUID
    var timestamp: String
    var description: String
    var image_storage_path: String?
    var timing_verdict: String?
    var hours_from_digestive_sunset: Double?
    var metabolic_insight: String?
    var claude_narrative: String?

    init(from m: FoodLog, userId: UUID) {
        id = m.id
        user_id = userId
        timestamp = iso.string(from: m.timestamp)
        description = m.description
        image_storage_path = nil
        timing_verdict = m.auditResult?.timingVerdict.rawValue
        hours_from_digestive_sunset = m.auditResult?.hoursFromDigestiveSunset
        metabolic_insight = m.auditResult?.metabolicInsight
        claude_narrative = m.auditResult?.claudeNarrative
    }

    func toModel() -> FoodLog {
        var audit: MetabolicAuditResult?
        if let tv = timing_verdict,
           let verdict = MetabolicAuditResult.TimingVerdict(rawValue: tv),
           let hours = hours_from_digestive_sunset,
           let insight = metabolic_insight,
           let narrative = claude_narrative {
            audit = MetabolicAuditResult(
                mealDescription: description,
                timingVerdict: verdict,
                hoursFromDigestiveSunset: hours,
                metabolicInsight: insight,
                claudeNarrative: narrative
            )
        }
        return FoodLog(
            id: id,
            timestamp: iso.date(from: timestamp) ?? Date(),
            description: description,
            imageData: nil,
            auditResult: audit
        )
    }
}

struct JetlagResultRow: Codable {
    var id: UUID
    var user_id: UUID
    var generated_at: String
    var average_midpoint: String
    var first_event_average: String
    var jetlag_hours: Double
    var chronotype_drift: String
    var claude_narrative: String
    var score: Int

    init(from m: SocialJetlagResult, userId: UUID) {
        id = UUID()
        user_id = userId
        generated_at = iso.string(from: m.generatedAt)
        average_midpoint = iso.string(from: m.averageMidpoint)
        first_event_average = iso.string(from: m.firstEventAverage)
        jetlag_hours = m.jetlagHours
        chronotype_drift = m.chronotypeDrift
        claude_narrative = m.claudeNarrative
        score = m.score
    }

    func toModel() -> SocialJetlagResult {
        SocialJetlagResult(
            generatedAt: iso.date(from: generated_at) ?? Date(),
            averageMidpoint: iso.date(from: average_midpoint) ?? Date(),
            firstEventAverage: iso.date(from: first_event_average) ?? Date(),
            jetlagHours: jetlag_hours,
            chronotypeDrift: chronotype_drift,
            claudeNarrative: claude_narrative,
            score: score
        )
    }
}

struct EnergyForecastRow: Codable {
    var id: UUID
    var user_id: UUID
    var date: String
    var hourly_energy_level: [String: Double]   // JSON keys must be strings
    var cognitive_clashes: [CognitiveClashJSON]
    var claude_narrative: String

    struct CognitiveClashJSON: Codable {
        var event_title: String
        var event_start: String
        var predicted_energy_level: Double
        var severity: String
        var suggestion: String
    }

    init(from m: EnergyForecast, userId: UUID) {
        id = UUID()
        user_id = userId
        date = dateFormatter.string(from: m.date)
        hourly_energy_level = Dictionary(uniqueKeysWithValues:
            m.hourlyEnergyLevel.map { ("\($0.key)", $0.value) }
        )
        cognitive_clashes = m.cognitiveClashes.map {
            CognitiveClashJSON(
                event_title: $0.eventTitle,
                event_start: iso.string(from: $0.eventStart),
                predicted_energy_level: $0.predictedEnergyLevel,
                severity: $0.severity.rawValue,
                suggestion: $0.suggestion
            )
        }
        claude_narrative = m.claudeNarrative
    }

    func toModel() -> EnergyForecast {
        let hourly = Dictionary(uniqueKeysWithValues:
            hourly_energy_level.compactMap { k, v -> (Int, Double)? in
                guard let h = Int(k) else { return nil }
                return (h, v)
            }
        )
        let clashes = cognitive_clashes.map { c -> CognitiveClash in
            CognitiveClash(
                eventTitle: c.event_title,
                eventStart: iso.date(from: c.event_start) ?? Date(),
                predictedEnergyLevel: c.predicted_energy_level,
                severity: ClashSeverity(rawValue: c.severity) ?? .medium,
                suggestion: c.suggestion
            )
        }
        return EnergyForecast(
            date: dateFormatter.date(from: date) ?? Date(),
            hourlyEnergyLevel: hourly,
            cognitiveClashes: clashes,
            claudeNarrative: claude_narrative
        )
    }
}

struct BioProtocolRow: Codable {
    var id: UUID
    var user_id: UUID
    var date: String
    var caffeine_window_start: String
    var peak_brain_window_start: String
    var peak_brain_window_end: String
    var digestive_sunset: String
    var protocol_items: [ProtocolItemJSON]
    var claude_narrative: String

    struct ProtocolItemJSON: Codable {
        var time: String
        var category: String
        var title: String
        var rationale: String
    }

    init(from m: BioProtocol, userId: UUID) {
        id = UUID()
        user_id = userId
        date = dateFormatter.string(from: m.date)
        caffeine_window_start = iso.string(from: m.caffeineWindowStart)
        peak_brain_window_start = iso.string(from: m.peakBrainWindowStart)
        peak_brain_window_end = iso.string(from: m.peakBrainWindowEnd)
        digestive_sunset = iso.string(from: m.digestiveSunset)
        protocol_items = m.protocolItems.map {
            ProtocolItemJSON(time: iso.string(from: $0.time), category: $0.category.rawValue,
                             title: $0.title, rationale: $0.rationale)
        }
        claude_narrative = m.claudeNarrative
    }

    func toModel() -> BioProtocol {
        let items = protocol_items.map { p -> ProtocolItem in
            ProtocolItem(
                time: iso.date(from: p.time) ?? Date(),
                category: ProtocolCategory(rawValue: p.category) ?? .cognitiveWork,
                title: p.title,
                rationale: p.rationale
            )
        }
        return BioProtocol(
            date: dateFormatter.date(from: date) ?? Date(),
            caffeineWindowStart: iso.date(from: caffeine_window_start) ?? Date(),
            peakBrainWindowStart: iso.date(from: peak_brain_window_start) ?? Date(),
            peakBrainWindowEnd: iso.date(from: peak_brain_window_end) ?? Date(),
            digestiveSunset: iso.date(from: digestive_sunset) ?? Date(),
            protocolItems: items,
            claudeNarrative: claude_narrative
        )
    }
}

// Shared date formatter for DATE columns (no time component)
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()
