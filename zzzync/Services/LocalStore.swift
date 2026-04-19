import Foundation

/// Local-first store: UserDefaults is always written first (sync, reliable),
/// then queued for resilient Supabase sync with retry.
final class LocalStore {
    static let shared = LocalStore()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let syncMetadataKey = "syncMetadata"
    private let pendingSyncTasksKey = "pendingCloudSyncTasks"
    private let contactTagsKey = "contactTags"
    private let emailStressSignalsKey = "emailStressSignals"
    private let fatigueAnswerKey = "fatigueAnswer"
    private let syncLock = NSLock()
    private var isFlushingPendingTasks = false

    private enum CloudSyncTask: String, CaseIterable {
        case sleep
        case biometrics
        case foodLogs
        case jetlag
        case energy
        case bioProtocol
    }

    private struct SyncMetadata: Codable {
        var sleepUpdatedAtById: [String: Date] = [:]
        var biometricUpdatedAtById: [String: Date] = [:]
        var foodUpdatedAtById: [String: Date] = [:]
        var jetlagUpdatedAt: Date?
        var energyUpdatedAt: Date?
        var bioProtocolUpdatedAt: Date?
    }

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Sleep

    func saveSleepRecords(_ records: [SleepRecord]) {
        save(records, key: "sleepRecords")
        var meta = loadSyncMetadata()
        for record in records {
            let key = record.id.uuidString
            let localWriteTime = record.wakeTime
            let existing = meta.sleepUpdatedAtById[key] ?? .distantPast
            meta.sleepUpdatedAtById[key] = max(existing, localWriteTime)
        }
        saveSyncMetadata(meta)
        enqueueCloudSync(.sleep)
    }

    func loadSleepRecords() -> [SleepRecord] {
        load(key: "sleepRecords") ?? []
    }

    // MARK: - Biometrics

    func saveBiometrics(_ records: [BiometricRecord]) {
        save(records, key: "biometrics")
        var meta = loadSyncMetadata()
        for record in records {
            let key = record.id.uuidString
            let localWriteTime = record.date
            let existing = meta.biometricUpdatedAtById[key] ?? .distantPast
            meta.biometricUpdatedAtById[key] = max(existing, localWriteTime)
        }
        saveSyncMetadata(meta)
        enqueueCloudSync(.biometrics)
    }

    func loadBiometrics() -> [BiometricRecord] {
        load(key: "biometrics") ?? []
    }

    // MARK: - Food Logs

    func saveFoodLogs(_ logs: [FoodLog]) {
        save(logs, key: "foodLogs")
        var meta = loadSyncMetadata()
        for log in logs {
            let key = log.id.uuidString
            let localWriteTime = log.timestamp
            let existing = meta.foodUpdatedAtById[key] ?? .distantPast
            meta.foodUpdatedAtById[key] = max(existing, localWriteTime)
        }
        saveSyncMetadata(meta)
        enqueueCloudSync(.foodLogs)
    }

    func loadFoodLogs() -> [FoodLog] {
        load(key: "foodLogs") ?? []
    }

    func appendFoodLog(_ log: FoodLog) {
        var logs = loadFoodLogs()
        logs.append(log)
        saveFoodLogs(logs)
    }

    // MARK: - Results cache

    func saveSocialJetlagResult(_ result: SocialJetlagResult) {
        save(result, key: "jetlagResult")
        var meta = loadSyncMetadata()
        meta.jetlagUpdatedAt = Date()
        saveSyncMetadata(meta)
        enqueueCloudSync(.jetlag)
    }

    func loadSocialJetlagResult() -> SocialJetlagResult? {
        load(key: "jetlagResult")
    }

    func saveBioProtocol(_ proto: BioProtocol) {
        save(proto, key: "bioProtocol")
        var meta = loadSyncMetadata()
        meta.bioProtocolUpdatedAt = Date()
        saveSyncMetadata(meta)
        enqueueCloudSync(.bioProtocol)
    }

    func loadBioProtocol() -> BioProtocol? {
        load(key: "bioProtocol")
    }

    func saveEnergyForecast(_ forecast: EnergyForecast) {
        save(forecast, key: "energyForecast")
        var meta = loadSyncMetadata()
        meta.energyUpdatedAt = Date()
        saveSyncMetadata(meta)
        enqueueCloudSync(.energy)
    }

    func loadEnergyForecast() -> EnergyForecast? {
        load(key: "energyForecast")
    }

    // MARK: - Email Intelligence cache

    func saveContactTags(_ tags: [ContactTag]) {
        save(tags, key: contactTagsKey)
    }

    func loadContactTags() -> [ContactTag] {
        load(key: contactTagsKey) ?? []
    }

    func saveEmailStressSignals(_ signals: [EmailStressSignal]) {
        save(signals, key: emailStressSignalsKey)
    }

    func loadEmailStressSignals() -> [EmailStressSignal] {
        load(key: emailStressSignalsKey) ?? []
    }

    // MARK: - AI Fatigue cache

    func saveFatigueAnswer(_ answer: FatigueAnswer) {
        save(answer, key: fatigueAnswerKey)
    }

    func loadFatigueAnswer() -> FatigueAnswer? {
        load(key: fatigueAnswerKey)
    }

    // MARK: - Cloud Sync

    /// Pulls latest data from Supabase and merges into local cache with last-write-wins.
    func syncFromCloud() async {
        do {
            let snapshot = try await SupabaseService.shared.fetchCloudSnapshot()
            var meta = loadSyncMetadata()

            // Sleep records
            let localSleep = loadSleepRecords()
            let remoteSleep = snapshot.sleepRows.map { $0.toModel() }
            let remoteSleepTimes = Dictionary(
                uniqueKeysWithValues: snapshot.sleepRows.map {
                    ($0.id.uuidString, $0.updatedAtDate ?? $0.toModel().bedtime)
                }
            )
            let (mergedSleep, mergedSleepMeta) = mergeById(
                local: localSleep,
                remote: remoteSleep,
                localTimes: meta.sleepUpdatedAtById,
                remoteTimes: remoteSleepTimes,
                id: { $0.id },
                localFallbackTime: { $0.bedtime },
                remoteFallbackTime: { $0.bedtime }
            )
            save(mergedSleep.sorted { $0.date < $1.date }, key: "sleepRecords")
            meta.sleepUpdatedAtById = mergedSleepMeta

            // Biometrics
            let localBio = loadBiometrics()
            let remoteBio = snapshot.biometricRows.map { $0.toModel() }
            let remoteBioTimes = Dictionary(
                uniqueKeysWithValues: snapshot.biometricRows.map {
                    ($0.id.uuidString, $0.updatedAtDate ?? $0.toModel().date)
                }
            )
            let (mergedBio, mergedBioMeta) = mergeById(
                local: localBio,
                remote: remoteBio,
                localTimes: meta.biometricUpdatedAtById,
                remoteTimes: remoteBioTimes,
                id: { $0.id },
                localFallbackTime: { $0.date },
                remoteFallbackTime: { $0.date }
            )
            save(mergedBio.sorted { $0.date < $1.date }, key: "biometrics")
            meta.biometricUpdatedAtById = mergedBioMeta

            // Food logs
            let localFood = loadFoodLogs()
            let remoteFood = snapshot.foodRows.map { $0.toModel() }
            let remoteFoodTimes = Dictionary(
                uniqueKeysWithValues: snapshot.foodRows.map {
                    ($0.id.uuidString, $0.updatedAtDate ?? $0.toModel().timestamp)
                }
            )
            let (mergedFood, mergedFoodMeta) = mergeById(
                local: localFood,
                remote: remoteFood,
                localTimes: meta.foodUpdatedAtById,
                remoteTimes: remoteFoodTimes,
                id: { $0.id },
                localFallbackTime: { $0.timestamp },
                remoteFallbackTime: { $0.timestamp }
            )
            save(mergedFood.sorted { $0.timestamp < $1.timestamp }, key: "foodLogs")
            meta.foodUpdatedAtById = mergedFoodMeta

            // Latest social jetlag
            if let remote = snapshot.jetlagRow?.toModel() {
                let remoteAt = snapshot.jetlagRow?.updatedAtDate ?? remote.generatedAt
                if shouldReplaceLocal(localTimestamp: meta.jetlagUpdatedAt ?? loadSocialJetlagResult()?.generatedAt,
                                      remoteTimestamp: remoteAt) {
                    save(remote, key: "jetlagResult")
                    meta.jetlagUpdatedAt = remoteAt
                }
            }

            // Latest energy forecast
            if let remote = snapshot.energyRow?.toModel() {
                let remoteAt = snapshot.energyRow?.updatedAtDate ?? remote.date
                if shouldReplaceLocal(localTimestamp: meta.energyUpdatedAt ?? loadEnergyForecast()?.date,
                                      remoteTimestamp: remoteAt) {
                    save(remote, key: "energyForecast")
                    meta.energyUpdatedAt = remoteAt
                }
            }

            // Latest bio protocol
            if let remote = snapshot.bioProtocolRow?.toModel() {
                let remoteAt = snapshot.bioProtocolRow?.updatedAtDate ?? remote.date
                if shouldReplaceLocal(localTimestamp: meta.bioProtocolUpdatedAt ?? loadBioProtocol()?.date,
                                      remoteTimestamp: remoteAt) {
                    save(remote, key: "bioProtocol")
                    meta.bioProtocolUpdatedAt = remoteAt
                }
            }

            saveSyncMetadata(meta)
            await flushPendingSync()
        } catch {
            print("[CloudSync] Failed: \(error.localizedDescription)")
        }
    }

    /// Attempts to flush pending cloud writes. Failed tasks stay queued for retry.
    func flushPendingSync() async {
        guard beginPendingFlush() else { return }
        defer { endPendingFlush() }

        var pending = Set(loadPendingTaskRawValues())
        let orderedTasks = CloudSyncTask.allCases.filter { pending.contains($0.rawValue) }

        guard !orderedTasks.isEmpty else { return }

        for task in orderedTasks {
            do {
                try await pushTaskToCloud(task)
                pending.remove(task.rawValue)
            } catch {
                print("[CloudSync] \(task.rawValue) push failed: \(error.localizedDescription)")
            }
        }

        savePendingTaskRawValues(Array(pending))
    }

    func enqueueFullCloudResync() {
        syncLock.lock()
        let allTasks = Set(CloudSyncTask.allCases.map(\.rawValue))
        let existing = Set(loadPendingTaskRawValues())
        savePendingTaskRawValues(Array(existing.union(allTasks)))
        syncLock.unlock()
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

    private func loadSyncMetadata() -> SyncMetadata {
        load(key: syncMetadataKey) ?? SyncMetadata()
    }

    private func saveSyncMetadata(_ metadata: SyncMetadata) {
        save(metadata, key: syncMetadataKey)
    }

    private func enqueueCloudSync(_ task: CloudSyncTask) {
        syncLock.lock()
        var pending = Set(loadPendingTaskRawValues())
        pending.insert(task.rawValue)
        savePendingTaskRawValues(Array(pending))
        syncLock.unlock()

        Task { await flushPendingSync() }
    }

    private func beginPendingFlush() -> Bool {
        syncLock.lock()
        defer { syncLock.unlock() }
        if isFlushingPendingTasks {
            return false
        }
        isFlushingPendingTasks = true
        return true
    }

    private func endPendingFlush() {
        syncLock.lock()
        isFlushingPendingTasks = false
        syncLock.unlock()
    }

    private func loadPendingTaskRawValues() -> [String] {
        defaults.stringArray(forKey: pendingSyncTasksKey) ?? []
    }

    private func savePendingTaskRawValues(_ values: [String]) {
        defaults.set(values, forKey: pendingSyncTasksKey)
    }

    private func pushTaskToCloud(_ task: CloudSyncTask) async throws {
        switch task {
        case .sleep:
            let records = loadSleepRecords()
            if !records.isEmpty {
                try await SupabaseService.shared.upsertSleepRecords(records)
            }
        case .biometrics:
            let records = loadBiometrics()
            if !records.isEmpty {
                try await SupabaseService.shared.upsertBiometrics(records)
            }
        case .foodLogs:
            let logs = loadFoodLogs()
            if !logs.isEmpty {
                try await SupabaseService.shared.upsertFoodLogs(logs)
            }
        case .jetlag:
            if let result = loadSocialJetlagResult() {
                try await SupabaseService.shared.upsertJetlagResult(result)
            }
        case .energy:
            if let forecast = loadEnergyForecast() {
                try await SupabaseService.shared.upsertEnergyForecast(forecast)
            }
        case .bioProtocol:
            if let protocolModel = loadBioProtocol() {
                try await SupabaseService.shared.upsertBioProtocol(protocolModel)
            }
        }
    }

    func clearAllLocalData() {
        let keys = [
            "sleepRecords",
            "biometrics",
            "foodLogs",
            "jetlagResult",
            "energyForecast",
            "bioProtocol",
            fatigueAnswerKey,
            contactTagsKey,
            emailStressSignalsKey,
            syncMetadataKey,
            pendingSyncTasksKey
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }

    private func mergeById<T>(
        local: [T],
        remote: [T],
        localTimes: [String: Date],
        remoteTimes: [String: Date],
        id: (T) -> UUID,
        localFallbackTime: (T) -> Date,
        remoteFallbackTime: (T) -> Date
    ) -> ([T], [String: Date]) {
        var localMap: [String: T] = [:]
        var remoteMap: [String: T] = [:]
        local.forEach { localMap[id($0).uuidString] = $0 }
        remote.forEach { remoteMap[id($0).uuidString] = $0 }

        let allIds = Set(localMap.keys).union(remoteMap.keys)
        var merged: [T] = []
        var mergedTimes: [String: Date] = [:]

        for key in allIds {
            let localItem = localMap[key]
            let remoteItem = remoteMap[key]

            switch (localItem, remoteItem) {
            case (let l?, let r?):
                let localAt = localTimes[key] ?? localFallbackTime(l)
                let remoteAt = remoteTimes[key] ?? remoteFallbackTime(r)
                if remoteAt >= localAt {
                    merged.append(r)
                    mergedTimes[key] = remoteAt
                } else {
                    merged.append(l)
                    mergedTimes[key] = localAt
                }
            case (let l?, nil):
                merged.append(l)
                mergedTimes[key] = localTimes[key] ?? localFallbackTime(l)
            case (nil, let r?):
                merged.append(r)
                mergedTimes[key] = remoteTimes[key] ?? remoteFallbackTime(r)
            default:
                continue
            }
        }

        return (merged, mergedTimes)
    }

    private func shouldReplaceLocal(localTimestamp: Date?, remoteTimestamp: Date?) -> Bool {
        guard let remoteTimestamp else { return false }
        guard let localTimestamp else { return true }
        return remoteTimestamp >= localTimestamp
    }
}
