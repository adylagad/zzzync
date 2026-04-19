import Foundation

/// Local-first store: UserDefaults is always written first (sync, reliable),
/// then Supabase is synced in the background (fire-and-forget).
final class LocalStore {
    static let shared = LocalStore()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Sleep

    func saveSleepRecords(_ records: [SleepRecord]) {
        save(records, key: "sleepRecords")
        Task { try? await SupabaseService.shared.upsertSleepRecords(records) }
    }

    func loadSleepRecords() -> [SleepRecord] {
        load(key: "sleepRecords") ?? []
    }

    // MARK: - Biometrics

    func saveBiometrics(_ records: [BiometricRecord]) {
        save(records, key: "biometrics")
        Task { try? await SupabaseService.shared.upsertBiometrics(records) }
    }

    func loadBiometrics() -> [BiometricRecord] {
        load(key: "biometrics") ?? []
    }

    // MARK: - Food Logs

    func saveFoodLogs(_ logs: [FoodLog]) {
        save(logs, key: "foodLogs")
    }

    func loadFoodLogs() -> [FoodLog] {
        load(key: "foodLogs") ?? []
    }

    func appendFoodLog(_ log: FoodLog) {
        var logs = loadFoodLogs()
        logs.append(log)
        saveFoodLogs(logs)
        Task { try? await SupabaseService.shared.insertFoodLog(log) }
    }

    // MARK: - Results cache

    func saveSocialJetlagResult(_ result: SocialJetlagResult) {
        save(result, key: "jetlagResult")
        Task { try? await SupabaseService.shared.upsertJetlagResult(result) }
    }

    func loadSocialJetlagResult() -> SocialJetlagResult? {
        load(key: "jetlagResult")
    }

    func saveBioProtocol(_ proto: BioProtocol) {
        save(proto, key: "bioProtocol")
        Task { try? await SupabaseService.shared.upsertBioProtocol(proto) }
    }

    func loadBioProtocol() -> BioProtocol? {
        load(key: "bioProtocol")
    }

    func saveEnergyForecast(_ forecast: EnergyForecast) {
        save(forecast, key: "energyForecast")
        Task { try? await SupabaseService.shared.upsertEnergyForecast(forecast) }
    }

    func loadEnergyForecast() -> EnergyForecast? {
        load(key: "energyForecast")
    }

    // MARK: - Private helpers

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func load<T: Decodable>(key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
