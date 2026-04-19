import Foundation

enum HackathonDemoScenario {
    private static let seedVersion = "hackathon-demo-v1"
    private static let seedVersionKey = "hackathonDemo.seedVersion"

    static var isEnabled: Bool { Constants.isHackathonDemoMode }

    static func installFixedDataIfNeeded(force: Bool = false) {
        guard isEnabled else { return }
        let defaults = UserDefaults.standard
        if !force, defaults.string(forKey: seedVersionKey) == seedVersion { return }

        LocalStore.shared.clearAllLocalData()
        LocalStore.shared.saveSleepRecords(sleepRecords)
        LocalStore.shared.saveBiometrics(biometrics)
        LocalStore.shared.saveFoodLogs(foodLogs)
        LocalStore.shared.saveSocialJetlagResult(jetlagResult)
        LocalStore.shared.saveEnergyForecast(energyForecast)
        LocalStore.shared.saveBioProtocol(bioProtocol)
        LocalStore.shared.saveContactTags(contactTags)
        LocalStore.shared.saveEmailStressSignals(emailStressSignals)

        defaults.set(seedVersion, forKey: seedVersionKey)
    }

    static var sleepRecords: [SleepRecord] {
        [
            SleepRecord(
                date: day(-6),
                bedtime: at(dayOffset: -7, hour: 0, minute: 40),
                wakeTime: at(dayOffset: -6, hour: 7, minute: 55),
                durationMinutes: 435,
                deepSleepMinutes: 58,
                remSleepMinutes: 86
            ),
            SleepRecord(
                date: day(-5),
                bedtime: at(dayOffset: -6, hour: 1, minute: 20),
                wakeTime: at(dayOffset: -5, hour: 8, minute: 20),
                durationMinutes: 420,
                deepSleepMinutes: 51,
                remSleepMinutes: 80
            ),
            SleepRecord(
                date: day(-4),
                bedtime: at(dayOffset: -5, hour: 2, minute: 10),
                wakeTime: at(dayOffset: -4, hour: 8, minute: 35),
                durationMinutes: 385,
                deepSleepMinutes: 43,
                remSleepMinutes: 68
            ),
            SleepRecord(
                date: day(-3),
                bedtime: at(dayOffset: -4, hour: 2, minute: 45),
                wakeTime: at(dayOffset: -3, hour: 8, minute: 10),
                durationMinutes: 325,
                deepSleepMinutes: 34,
                remSleepMinutes: 55
            ),
            // Day before yesterday: near-total sleep loss
            SleepRecord(
                date: day(-2),
                bedtime: at(dayOffset: -2, hour: 5, minute: 10),
                wakeTime: at(dayOffset: -2, hour: 5, minute: 45),
                durationMinutes: 35,
                deepSleepMinutes: 0,
                remSleepMinutes: 0
            ),
            // Yesterday to today: second all-nighter with only micro-nap
            SleepRecord(
                date: day(-1),
                bedtime: at(dayOffset: -1, hour: 4, minute: 40),
                wakeTime: at(dayOffset: -1, hour: 5, minute: 0),
                durationMinutes: 20,
                deepSleepMinutes: 0,
                remSleepMinutes: 0
            )
        ]
    }

    static var biometrics: [BiometricRecord] {
        [
            BiometricRecord(date: day(-6), hrvMs: 48, rhrBpm: 58, activeEnergyKcal: 420),
            BiometricRecord(date: day(-5), hrvMs: 46, rhrBpm: 60, activeEnergyKcal: 390),
            BiometricRecord(date: day(-4), hrvMs: 43, rhrBpm: 62, activeEnergyKcal: 410),
            BiometricRecord(date: day(-3), hrvMs: 38, rhrBpm: 67, activeEnergyKcal: 470),
            BiometricRecord(date: day(-2), hrvMs: 27, rhrBpm: 76, activeEnergyKcal: 610),
            BiometricRecord(date: day(-1), hrvMs: 18, rhrBpm: 84, activeEnergyKcal: 730),
            BiometricRecord(date: day(0), hrvMs: 14, rhrBpm: 88, activeEnergyKcal: 520)
        ]
    }

    static var contactTags: [ContactTag] {
        [
            ContactTag(email: "judgepanel@hackcity.org", priority: .high),
            ContactTag(email: "sponsor@hackcity.org", priority: .high),
            ContactTag(email: "teammate@hackcity.org", priority: .low)
        ]
    }

    static var emailStressSignals: [EmailStressSignal] {
        [
            EmailStressSignal(
                id: UUID(),
                provider: .gmail,
                senderEmail: "judgepanel@hackcity.org",
                senderPriority: .high,
                unreadThreads: 4,
                threadLengthScore: 6,
                subjectKeywords: ["urgent", "review"],
                stressScore: 92,
                generatedAt: Date()
            ),
            EmailStressSignal(
                id: UUID(),
                provider: .gmail,
                senderEmail: "sponsor@hackcity.org",
                senderPriority: .high,
                unreadThreads: 3,
                threadLengthScore: 5,
                subjectKeywords: ["deadline", "critical"],
                stressScore: 88,
                generatedAt: Date()
            ),
            EmailStressSignal(
                id: UUID(),
                provider: .gmail,
                senderEmail: "teammate@hackcity.org",
                senderPriority: .low,
                unreadThreads: 7,
                threadLengthScore: 7,
                subjectKeywords: ["asap"],
                stressScore: 62,
                generatedAt: Date()
            )
        ]
    }

    static var allCalendarEvents: [CalendarEvent] {
        [
            CalendarEvent(title: "Project Planning", startDate: at(dayOffset: -6, hour: 9, minute: 0), endDate: at(dayOffset: -6, hour: 9, minute: 30), stressWeight: 0.5),
            CalendarEvent(title: "Team Check-in", startDate: at(dayOffset: -5, hour: 9, minute: 10), endDate: at(dayOffset: -5, hour: 9, minute: 40), stressWeight: 0.55),
            CalendarEvent(title: "Prototype Sync", startDate: at(dayOffset: -4, hour: 9, minute: 20), endDate: at(dayOffset: -4, hour: 10, minute: 0), stressWeight: 0.65),
            CalendarEvent(title: "Mentor Office Hour", startDate: at(dayOffset: -3, hour: 9, minute: 15), endDate: at(dayOffset: -3, hour: 10, minute: 0), stressWeight: 0.7),
            CalendarEvent(title: "Hackathon Registration", startDate: at(dayOffset: -2, hour: 8, minute: 45), endDate: at(dayOffset: -2, hour: 9, minute: 30), stressWeight: 0.85),
            CalendarEvent(title: "Hackathon Day 1 Kickoff", startDate: at(dayOffset: -1, hour: 8, minute: 30), endDate: at(dayOffset: -1, hour: 10, minute: 0), stressWeight: 0.95),

            CalendarEvent(title: "Hackathon Standup", startDate: at(dayOffset: 0, hour: 9, minute: 30), endDate: at(dayOffset: 0, hour: 10, minute: 0), stressWeight: 0.8),
            CalendarEvent(title: "Sponsor Demo Review", startDate: at(dayOffset: 0, hour: 11, minute: 0), endDate: at(dayOffset: 0, hour: 11, minute: 45), stressWeight: 0.9),
            CalendarEvent(title: "Judging Round 1", startDate: at(dayOffset: 0, hour: 14, minute: 0), endDate: at(dayOffset: 0, hour: 15, minute: 0), stressWeight: 1.0),
            CalendarEvent(title: "Final Pitch Prep", startDate: at(dayOffset: 0, hour: 18, minute: 0), endDate: at(dayOffset: 0, hour: 19, minute: 30), stressWeight: 0.95),
            CalendarEvent(title: "Late-night Build Sprint", startDate: at(dayOffset: 0, hour: 21, minute: 0), endDate: at(dayOffset: 0, hour: 23, minute: 30), stressWeight: 0.88)
        ]
    }

    static var todayEvents: [CalendarEvent] {
        allCalendarEvents
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: Date()) }
            .sorted { $0.startDate < $1.startDate }
    }

    static var firstEventsThisWeek: [CalendarEvent] {
        var firstByDay: [Date: CalendarEvent] = [:]
        for event in allCalendarEvents {
            let key = Calendar.current.startOfDay(for: event.startDate)
            if let current = firstByDay[key] {
                if event.startDate < current.startDate { firstByDay[key] = event }
            } else {
                firstByDay[key] = event
            }
        }
        return firstByDay.values.sorted { $0.startDate < $1.startDate }
    }

    static var jetlagResult: SocialJetlagResult {
        SocialJetlagResult(
            generatedAt: Date(),
            averageMidpoint: at(dayOffset: 0, hour: 10, minute: 40),
            firstEventAverage: at(dayOffset: 0, hour: 9, minute: 15),
            jetlagHours: 5.8,
            chronotypeDrift: "Two all-nighters pushed your body clock far behind hackathon demand.",
            claudeNarrative: "Severe circadian debt from two all-nighters is driving unstable focus and recovery.",
            score: 18
        )
    }

    static var energyForecast: EnergyForecast {
        let hourly: [Int: Double] = [
            0: 0.28, 1: 0.24, 2: 0.20, 3: 0.18, 4: 0.17, 5: 0.19,
            6: 0.22, 7: 0.27, 8: 0.34, 9: 0.46, 10: 0.50, 11: 0.45,
            12: 0.39, 13: 0.30, 14: 0.22, 15: 0.20, 16: 0.24, 17: 0.29,
            18: 0.26, 19: 0.21, 20: 0.18, 21: 0.16, 22: 0.15, 23: 0.14
        ]

        let clashes = [
            CognitiveClash(
                eventTitle: "Sponsor Demo Review",
                eventStart: at(dayOffset: 0, hour: 11, minute: 0),
                predictedEnergyLevel: 0.45,
                severity: .medium,
                suggestion: "Use checklist and keep demo script tight."
            ),
            CognitiveClash(
                eventTitle: "Judging Round 1",
                eventStart: at(dayOffset: 0, hour: 14, minute: 0),
                predictedEnergyLevel: 0.22,
                severity: .high,
                suggestion: "Take 20-min reset before judging and split speaking roles."
            ),
            CognitiveClash(
                eventTitle: "Final Pitch Prep",
                eventStart: at(dayOffset: 0, hour: 18, minute: 0),
                predictedEnergyLevel: 0.26,
                severity: .high,
                suggestion: "Prioritize one narrative, cut extras, and rehearse once."
            )
        ]

        return EnergyForecast(
            date: Date(),
            hourlyEnergyLevel: hourly,
            cognitiveClashes: clashes,
            claudeNarrative: "Two all-nighters and 800mg caffeine mask severe cognitive debt."
        )
    }

    static var bioProtocol: BioProtocol {
        BioProtocol(
            date: Date(),
            caffeineWindowStart: at(dayOffset: 0, hour: 15, minute: 30),
            peakBrainWindowStart: at(dayOffset: 0, hour: 10, minute: 30),
            peakBrainWindowEnd: at(dayOffset: 0, hour: 11, minute: 30),
            digestiveSunset: at(dayOffset: 0, hour: 19, minute: 0),
            protocolItems: [
                ProtocolItem(
                    time: at(dayOffset: 0, hour: 10, minute: 20),
                    category: .cognitiveWork,
                    title: "Ship critical tasks only",
                    rationale: "Use your brief rebound window for must-finish tasks."
                ),
                ProtocolItem(
                    time: at(dayOffset: 0, hour: 13, minute: 20),
                    category: .rest,
                    title: "20-min eyes-closed reset",
                    rationale: "Lower sleep-pressure before judging block."
                ),
                ProtocolItem(
                    time: at(dayOffset: 0, hour: 13, minute: 50),
                    category: .meal,
                    title: "Protein + fiber meal",
                    rationale: "Blunt sugar crash before afternoon sessions."
                ),
                ProtocolItem(
                    time: at(dayOffset: 0, hour: 15, minute: 30),
                    category: .caffeine,
                    title: "No more caffeine today",
                    rationale: "You already consumed ~800mg in 36h."
                ),
                ProtocolItem(
                    time: at(dayOffset: 0, hour: 19, minute: 0),
                    category: .meal,
                    title: "Last meal cutoff",
                    rationale: "Protect overnight recovery after prolonged wakefulness."
                ),
                ProtocolItem(
                    time: at(dayOffset: 0, hour: 22, minute: 30),
                    category: .rest,
                    title: "Hard stop and sleep",
                    rationale: "Priority is circadian recovery over extra coding hours."
                )
            ],
            claudeNarrative: "Recovery-first pacing beats extra caffeine after two consecutive all-nighters."
        )
    }

    static var foodLogs: [FoodLog] {
        [
            FoodLog(
                timestamp: at(dayOffset: -1, hour: 8, minute: 45),
                description: "Energy drink + donut (65g sugar, 300mg caffeine)",
                auditResult: MetabolicAuditResult(
                    mealDescription: "Energy drink + donut",
                    timingVerdict: .offClock,
                    hoursFromDigestiveSunset: -10.2,
                    metabolicInsight: "Large sugar+caffeine stack drove unstable energy.",
                    claudeNarrative: "Fast sugar plus heavy caffeine widened later crash risk."
                )
            ),
            FoodLog(
                timestamp: at(dayOffset: -1, hour: 13, minute: 10),
                description: "Candy + cold brew (35g sugar, 300mg caffeine)",
                auditResult: MetabolicAuditResult(
                    mealDescription: "Candy + cold brew",
                    timingVerdict: .offClock,
                    hoursFromDigestiveSunset: -5.8,
                    metabolicInsight: "Second stimulant peak increased evening dysregulation.",
                    claudeNarrative: "Cumulative caffeine load likely delayed real sleep onset."
                )
            ),
            FoodLog(
                timestamp: at(dayOffset: -1, hour: 22, minute: 40),
                description: "Pizza slice + fries + soda",
                auditResult: MetabolicAuditResult(
                    mealDescription: "Pizza + fries + soda",
                    timingVerdict: .offClock,
                    hoursFromDigestiveSunset: 3.7,
                    metabolicInsight: "Late heavy meal increased overnight metabolic strain.",
                    claudeNarrative: "Night eating during stress compounds circadian mismatch."
                )
            ),
            FoodLog(
                timestamp: at(dayOffset: 0, hour: 1, minute: 55),
                description: "Instant noodles + chips",
                auditResult: MetabolicAuditResult(
                    mealDescription: "Noodles + chips",
                    timingVerdict: .offClock,
                    hoursFromDigestiveSunset: 6.9,
                    metabolicInsight: "Overnight refined carbs extended wake-cycle volatility.",
                    claudeNarrative: "Overnight snacking reinforced sleep-loss physiology."
                )
            ),
            FoodLog(
                timestamp: at(dayOffset: 0, hour: 9, minute: 20),
                description: "Energy drink + pastry (200mg caffeine)",
                auditResult: MetabolicAuditResult(
                    mealDescription: "Energy drink + pastry",
                    timingVerdict: .borderline,
                    hoursFromDigestiveSunset: -9.7,
                    metabolicInsight: "Third caffeine wave may mask cognitive fatigue temporarily.",
                    claudeNarrative: "Short alertness boost, followed by sharper afternoon dip."
                )
            ),
            FoodLog(
                timestamp: at(dayOffset: 0, hour: 12, minute: 30),
                description: "Burger + fries + soda",
                auditResult: MetabolicAuditResult(
                    mealDescription: "Burger + fries + soda",
                    timingVerdict: .offClock,
                    hoursFromDigestiveSunset: -6.5,
                    metabolicInsight: "High-fat + high-sugar lunch reduced post-meal focus stability.",
                    claudeNarrative: "Heavy lunch deepened crash during judging window."
                )
            )
        ]
    }

    private static func day(_ dayOffset: Int) -> Date {
        Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: dayOffset, to: todayStart)!
        )
    }

    private static func at(dayOffset: Int, hour: Int, minute: Int) -> Date {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: todayStart)!
        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        )!
    }

    private static var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }
}
