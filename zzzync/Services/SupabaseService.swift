import Foundation
import Supabase

// MARK: - Client

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Constants.supabaseURL)!,
            supabaseKey: Constants.supabaseAnonKey
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

    var accessToken: String? {
        get async {
            try? await client.auth.session.accessToken
        }
    }

    struct AccountProfile {
        let userId: UUID?
        let email: String?
        let providers: [String]
        let isAnonymous: Bool

        static let signedOut = AccountProfile(
            userId: nil,
            email: nil,
            providers: [],
            isAnonymous: true
        )
    }

    func accountProfile() async -> AccountProfile {
        guard let session = try? await client.auth.session else { return .signedOut }
        let identities = (try? await client.auth.userIdentities()) ?? []
        let providers = identities.map { String(describing: $0.provider) }
            .filter { !$0.isEmpty }
            .sorted()
        let isAnonymous = providers.isEmpty || providers == ["anonymous"]
        return AccountProfile(
            userId: session.user.id,
            email: session.user.email,
            providers: providers,
            isAnonymous: isAnonymous
        )
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        _ = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
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

    func fetchBiometrics(days: Int = 14) async throws -> [BiometricRecord] {
        guard let userId = await currentUserId else { return [] }
        let since = ISO8601DateFormatter().string(
            from: Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        )
        let rows: [BiometricRecordRow] = try await client.from("biometric_records")
            .select()
            .eq("user_id", value: userId)
            .gte("date", value: since)
            .order("date", ascending: false)
            .execute()
            .value
        return rows.map { $0.toModel() }
    }

    // MARK: - Food Logs

    func insertFoodLog(_ log: FoodLog) async throws {
        guard let userId = await currentUserId else { return }
        let row = FoodLogRow(from: log, userId: userId)
        try await client.from("food_logs")
            .insert(row)
            .execute()
    }

    func upsertFoodLogs(_ logs: [FoodLog]) async throws {
        guard !logs.isEmpty else { return }
        guard let userId = await currentUserId else { return }
        let rows = logs.map { FoodLogRow(from: $0, userId: userId) }
        try await client.from("food_logs")
            .upsert(rows, onConflict: "id")
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

    // MARK: - Cloud Snapshot (Phase 2 sync)

    struct CloudSnapshot {
        let sleepRows: [SleepRecordRow]
        let biometricRows: [BiometricRecordRow]
        let foodRows: [FoodLogRow]
        let jetlagRow: JetlagResultRow?
        let energyRow: EnergyForecastRow?
        let bioProtocolRow: BioProtocolRow?

        static let empty = CloudSnapshot(
            sleepRows: [],
            biometricRows: [],
            foodRows: [],
            jetlagRow: nil,
            energyRow: nil,
            bioProtocolRow: nil
        )
    }

    func fetchCloudSnapshot() async throws -> CloudSnapshot {
        guard let userId = await currentUserId else { return .empty }

        async let sleepRowsTask: [SleepRecordRow] = client.from("sleep_records")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value

        async let biometricRowsTask: [BiometricRecordRow] = client.from("biometric_records")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value

        async let foodRowsTask: [FoodLogRow] = client.from("food_logs")
            .select()
            .eq("user_id", value: userId)
            .order("timestamp", ascending: false)
            .execute()
            .value

        async let jetlagRowsTask: [JetlagResultRow] = client.from("social_jetlag_results")
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value

        async let energyRowsTask: [EnergyForecastRow] = client.from("energy_forecasts")
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value

        async let bioRowsTask: [BioProtocolRow] = client.from("bio_protocols")
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value

        let (sleepRows, biometricRows, foodRows, jetlagRows, energyRows, bioRows) = try await (
            sleepRowsTask,
            biometricRowsTask,
            foodRowsTask,
            jetlagRowsTask,
            energyRowsTask,
            bioRowsTask
        )

        return CloudSnapshot(
            sleepRows: sleepRows,
            biometricRows: biometricRows,
            foodRows: foodRows,
            jetlagRow: jetlagRows.first,
            energyRow: energyRows.first,
            bioProtocolRow: bioRows.first
        )
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
    var updated_at: String?

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

    var updatedAtDate: Date? { parseISODate(updated_at) }
}

struct BiometricRecordRow: Codable {
    var id: UUID
    var user_id: UUID
    var date: String
    var hrv_ms: Double?
    var rhr_bpm: Double?
    var active_energy_kcal: Double?
    var updated_at: String?

    init(from m: BiometricRecord, userId: UUID) {
        id = m.id
        user_id = userId
        date = dateFormatter.string(from: m.date)
        hrv_ms = m.hrvMs
        rhr_bpm = m.rhrBpm
        active_energy_kcal = m.activeEnergyKcal
    }

    func toModel() -> BiometricRecord {
        BiometricRecord(
            id: id,
            date: dateFormatter.date(from: date) ?? Date(),
            hrvMs: hrv_ms,
            rhrBpm: rhr_bpm,
            activeEnergyKcal: active_energy_kcal
        )
    }

    var updatedAtDate: Date? { parseISODate(updated_at) }
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
    var updated_at: String?

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

    var updatedAtDate: Date? { parseISODate(updated_at) }
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
    var updated_at: String?

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

    var updatedAtDate: Date? { parseISODate(updated_at) }
}

struct EnergyForecastRow: Codable {
    var id: UUID
    var user_id: UUID
    var date: String
    var hourly_energy_level: [String: Double]   // JSON keys must be strings
    var cognitive_clashes: [CognitiveClashJSON]
    var claude_narrative: String
    var updated_at: String?

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

    var updatedAtDate: Date? { parseISODate(updated_at) }
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
    var updated_at: String?

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

    var updatedAtDate: Date? { parseISODate(updated_at) }
}

// Shared date formatter for DATE columns (no time component)
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private func parseISODate(_ value: String?) -> Date? {
    guard let value, !value.isEmpty else { return nil }
    return iso.date(from: value)
}
