import Foundation
import Observation
import SwiftUI

@Observable
final class AICausalViewModel {
    struct SignalChip: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let color: Color
    }

    var question = "Why am I tired?"
    var answer: FatigueAnswer?
    var isLoading = false
    var error: String?
    var signalChips: [SignalChip] = []

    func load() {
        if HackathonDemoScenario.isEnabled {
            HackathonDemoScenario.installFixedDataIfNeeded(force: false)
        }
        answer = LocalStore.shared.loadFatigueAnswer()
        refreshSignalChips()
    }

    func ask() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            if HackathonDemoScenario.isEnabled {
                HackathonDemoScenario.installFixedDataIfNeeded(force: false)
            }

            var sleep = LocalStore.shared.loadSleepRecords()
            var biometrics = LocalStore.shared.loadBiometrics()

            if sleep.isEmpty {
                sleep = try await HealthKitService.shared.fetchSleepRecords()
                LocalStore.shared.saveSleepRecords(sleep)
            }
            if biometrics.isEmpty {
                biometrics = try await HealthKitService.shared.fetchBiometrics()
                LocalStore.shared.saveBiometrics(biometrics)
            }

            let foodLogs = LocalStore.shared.loadFoodLogs()
            let jetlag = LocalStore.shared.loadSocialJetlagResult()
            let forecast = LocalStore.shared.loadEnergyForecast()
            let events = CalendarService.shared.fetchTodayEvents()
            let emailSignals = LocalStore.shared.loadEmailStressSignals()

            let response = try await ClaudeService.shared.explainFatigue(
                question: question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Why am I tired?"
                    : question,
                sleepRecords: sleep,
                biometrics: biometrics,
                foodLogs: foodLogs,
                jetlagResult: jetlag,
                forecast: forecast,
                todayEvents: events,
                emailStressSignals: emailSignals
            )

            LocalStore.shared.saveFatigueAnswer(response)

            await MainActor.run {
                answer = response
                refreshSignalChips()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                self.refreshSignalChips()
            }
        }
    }

    func useDefaultQuestion() {
        question = "Why am I tired?"
    }

    private func refreshSignalChips() {
        let sleep = LocalStore.shared.loadSleepRecords()
        let biometrics = LocalStore.shared.loadBiometrics()
        let jetlag = LocalStore.shared.loadSocialJetlagResult()
        let food = LocalStore.shared.loadFoodLogs()
        let email = LocalStore.shared.loadEmailStressSignals()

        let lastSleepHours = sleep.last.map { Double($0.durationMinutes) / 60.0 } ?? 0
        let offClockMeals = food.filter { $0.auditResult?.timingVerdict == .offClock }.count
        let (caffeineMg, sugarG) = extractStimulants(foodLogs: food)
        let highPressureEmails = email.filter { $0.stressScore >= 75 }.count

        signalChips = [
            SignalChip(
                title: "Sleep",
                value: sleep.isEmpty ? "N/A" : String(format: "%.1fh", lastSleepHours),
                color: .zzzyncBlue
            ),
            SignalChip(
                title: "HRV",
                value: biometrics.last?.hrvMs.map { String(format: "%.0f ms", $0) } ?? "N/A",
                color: .zzzyncTeal
            ),
            SignalChip(
                title: "RHR",
                value: biometrics.last?.rhrBpm.map { String(format: "%.0f bpm", $0) } ?? "N/A",
                color: .zzzyncRed
            ),
            SignalChip(
                title: "Jetlag",
                value: jetlag.map { String(format: "%.1fh", abs($0.jetlagHours)) } ?? "N/A",
                color: .zzzyncPrimary
            ),
            SignalChip(
                title: "Off-clock Meals",
                value: "\(offClockMeals)",
                color: .zzzyncAccent
            ),
            SignalChip(
                title: "Caffeine",
                value: caffeineMg > 0 ? "\(caffeineMg)mg" : "N/A",
                color: .zzzyncGreen
            ),
            SignalChip(
                title: "Sugar",
                value: sugarG > 0 ? "\(sugarG)g" : "N/A",
                color: .zzzyncScoreWarn
            ),
            SignalChip(
                title: "Email Pressure",
                value: "\(highPressureEmails)",
                color: .zzzyncRed
            )
        ]
    }

    private func extractStimulants(foodLogs: [FoodLog]) -> (caffeineMg: Int, sugarG: Int) {
        let text = foodLogs.map(\.description).joined(separator: " ").lowercased()
        let caffeine = sumMatches(in: text, pattern: #"(\d+)\s*mg\s*caffeine"#)
        let sugar = sumMatches(in: text, pattern: #"(\d+)\s*g\s*sugar"#)
        return (caffeine, sugar)
    }

    private func sumMatches(in text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).reduce(0) { partial, match in
            guard match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: text),
                  let value = Int(text[valueRange]) else { return partial }
            return partial + value
        }
    }
}
