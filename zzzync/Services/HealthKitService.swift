import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    private init() {}

    // MARK: - Permissions

    func requestPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Sleep

    /// Returns one SleepRecord per sleep session for the past N days.
    func fetchSleepRecords(days: Int = Constants.sleepLookbackDays) async throws -> [SleepRecord] {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, results, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        return groupSleepSamples(samples)
    }

    // MARK: - Biometrics

    func fetchBiometrics(days: Int = Constants.biometricLookbackDays) async throws -> [BiometricRecord] {
        async let hrv = fetchDailyAverages(quantityType: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), days: days)
        async let rhr = fetchDailyAverages(quantityType: .restingHeartRate, unit: HKUnit(from: "count/min"), days: days)

        let (hrvMap, rhrMap) = try await (hrv, rhr)

        var records: [BiometricRecord] = []
        let allDates = Set(hrvMap.keys).union(rhrMap.keys)
        for date in allDates.sorted() {
            records.append(BiometricRecord(
                date: date,
                hrvMs: hrvMap[date],
                rhrBpm: rhrMap[date]
            ))
        }
        return records
    }

    // MARK: - Private helpers

    private func groupSleepSamples(_ samples: [HKCategorySample]) -> [SleepRecord] {
        // Filter to actual sleep (asleep stages), not in-bed
        let asleep = samples.filter { sample in
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
            if #available(iOS 16.0, *) {
                return value == .asleepUnspecified || value == .asleepCore ||
                       value == .asleepDeep || value == .asleepREM
            } else {
                return value == .asleep
            }
        }

        guard !asleep.isEmpty else { return [] }

        // Group into sessions: gap > 30 minutes = new session
        var sessions: [[HKCategorySample]] = [[asleep[0]]]
        for sample in asleep.dropFirst() {
            let lastEnd = sessions.last!.last!.endDate
            if sample.startDate.timeIntervalSince(lastEnd) < Constants.sleepSessionGapSeconds {
                sessions[sessions.count - 1].append(sample)
            } else {
                sessions.append([sample])
            }
        }

        return sessions.compactMap { session -> SleepRecord? in
            guard let first = session.first, let last = session.last else { return nil }
            let bedtime = first.startDate
            let wakeTime = last.endDate
            let totalMinutes = Int(wakeTime.timeIntervalSince(bedtime) / 60)
            guard totalMinutes > 60 else { return nil }  // skip very short sessions

            var deep = 0, rem = 0
            for s in session {
                let minutes = Int(s.endDate.timeIntervalSince(s.startDate) / 60)
                if #available(iOS 16.0, *) {
                    if HKCategoryValueSleepAnalysis(rawValue: s.value) == .asleepDeep { deep += minutes }
                    if HKCategoryValueSleepAnalysis(rawValue: s.value) == .asleepREM  { rem  += minutes }
                }
            }

            return SleepRecord(
                date: bedtime.startOfDay,
                bedtime: bedtime,
                wakeTime: wakeTime,
                durationMinutes: totalMinutes,
                deepSleepMinutes: deep,
                remSleepMinutes: rem
            )
        }
    }

    private func fetchDailyAverages(
        quantityType identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        days: Int
    ) async throws -> [Date: Double] {
        let type = HKObjectType.quantityType(forIdentifier: identifier)!
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let anchorDate = Calendar.current.startOfDay(for: start)
        let interval = DateComponents(day: 1)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: Date()),
                options: .discreteAverage,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, error in
                if let error { cont.resume(throwing: error); return }
                var map: [Date: Double] = [:]
                results?.enumerateStatistics(from: start, to: Date()) { stats, _ in
                    if let qty = stats.averageQuantity() {
                        map[stats.startDate.startOfDay] = qty.doubleValue(for: unit)
                    }
                }
                cont.resume(returning: map)
            }
            store.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        "HealthKit is not available on this device."
    }
}
