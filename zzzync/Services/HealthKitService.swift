import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    private init() {}

    // MARK: - Permissions

    func requestPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }   // simulator / no HealthKit → skip silently

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        // requestAuthorization never throws on denial — it only throws on system errors
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Sleep

    func fetchSleepRecords(days: Int = Constants.sleepLookbackDays) async throws -> [SleepRecord] {
        if HackathonDemoScenario.isEnabled {
            return Array(HackathonDemoScenario.sleepRecords.suffix(days))
        }
        guard HKHealthStore.isHealthDataAvailable() else { return mockSleepRecords(days: days) }

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

        let real = groupSleepSamples(samples)
        // If HealthKit returned nothing (no data logged yet), fall back to mock
        return real.isEmpty ? mockSleepRecords(days: days) : real
    }

    // MARK: - Biometrics

    func fetchBiometrics(days: Int = Constants.biometricLookbackDays) async throws -> [BiometricRecord] {
        if HackathonDemoScenario.isEnabled {
            return Array(HackathonDemoScenario.biometrics.suffix(days))
        }
        guard HKHealthStore.isHealthDataAvailable() else { return mockBiometrics(days: days) }

        async let hrv = fetchDailyAverages(quantityType: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), days: days)
        async let rhr = fetchDailyAverages(quantityType: .restingHeartRate, unit: HKUnit(from: "count/min"), days: days)

        let (hrvMap, rhrMap) = try await (hrv, rhr)

        var records: [BiometricRecord] = []
        let allDates = Set(hrvMap.keys).union(rhrMap.keys)
        for date in allDates.sorted() {
            records.append(BiometricRecord(date: date, hrvMs: hrvMap[date], rhrBpm: rhrMap[date]))
        }

        return records.isEmpty ? mockBiometrics(days: days) : records
    }

    // MARK: - Mock data (realistic social jetlag scenario for demo)

    /// Simulates a night-owl whose body clock runs ~2h behind their 9 AM calendar.
    func mockSleepRecords(days: Int = 7) -> [SleepRecord] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Bedtimes drift later on weekends (the classic social jetlag pattern)
        let bedtimeOffsets: [TimeInterval] = [
            -1 * 3600,   // 7 days ago: 1 AM
             0,          // 6 days ago: midnight
            -2 * 3600,   // 5 days ago (Fri): 2 AM — weekend drift starts
            -3 * 3600,   // 4 days ago (Sat): 3 AM
            -2.5 * 3600, // 3 days ago (Sun): 2:30 AM
            -1 * 3600,   // 2 days ago: 1 AM
             0,          // yesterday: midnight
        ]
        let durationOffsets: [Double] = [450, 460, 480, 500, 490, 455, 465] // minutes of sleep

        return (0..<min(days, bedtimeOffsets.count)).compactMap { i in
            let dayOffset = -(days - 1 - i)
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: today) else { return nil }

            // Bedtime = previous midnight + offset (so "1 AM" = 1h after midnight)
            let midnight = cal.date(byAdding: .day, value: -1, to: date)!
            let bedtime = Date(timeInterval: 24 * 3600 + bedtimeOffsets[i], since: midnight)
            let duration = durationOffsets[i] * 60
            let wakeTime = bedtime.addingTimeInterval(duration)

            return SleepRecord(
                date: date,
                bedtime: bedtime,
                wakeTime: wakeTime,
                durationMinutes: Int(durationOffsets[i]),
                deepSleepMinutes: Int(durationOffsets[i] * 0.18),
                remSleepMinutes: Int(durationOffsets[i] * 0.22)
            )
        }
    }

    func mockBiometrics(days: Int = 7) -> [BiometricRecord] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // HRV dips on weekend (social jetlag stress), RHR ticks up slightly
        let hrvValues: [Double] = [42, 38, 31, 28, 35, 40, 44]
        let rhrValues: [Double] = [58, 60, 64, 66, 62, 59, 57]

        return (0..<min(days, hrvValues.count)).compactMap { i in
            let dayOffset = -(days - 1 - i)
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
            return BiometricRecord(date: date, hrvMs: hrvValues[i], rhrBpm: rhrValues[i])
        }
    }

    // MARK: - Private helpers

    private func groupSleepSamples(_ samples: [HKCategorySample]) -> [SleepRecord] {
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
            guard totalMinutes > 60 else { return nil }

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

        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: Date()),
                options: .discreteAverage,
                anchorDate: anchorDate,
                intervalComponents: DateComponents(day: 1)
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
    var errorDescription: String? { "HealthKit is not available on this device." }
}
