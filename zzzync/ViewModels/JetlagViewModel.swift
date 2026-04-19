import Foundation
import Observation

@Observable
final class JetlagViewModel {
    var sleepRecords: [SleepRecord] = []
    var firstEvents: [CalendarEvent] = []
    var result: SocialJetlagResult?
    var isLoading = false
    var error: String?

    func load() {
        if HackathonDemoScenario.isEnabled {
            HackathonDemoScenario.installFixedDataIfNeeded(force: false)
        }
        sleepRecords = LocalStore.shared.loadSleepRecords()
        firstEvents = CalendarService.shared.fetchFirstEventsThisWeek()
        result = LocalStore.shared.loadSocialJetlagResult()
    }

    func analyze() async {
        if HackathonDemoScenario.isEnabled {
            HackathonDemoScenario.installFixedDataIfNeeded(force: true)
            await MainActor.run {
                self.sleepRecords = LocalStore.shared.loadSleepRecords()
                self.firstEvents = CalendarService.shared.fetchFirstEventsThisWeek()
                self.result = LocalStore.shared.loadSocialJetlagResult()
                self.error = nil
                self.isLoading = false
            }
            return
        }

        await MainActor.run { isLoading = true; error = nil }
        do {
            let sleep = try await HealthKitService.shared.fetchSleepRecords()
            let events = CalendarService.shared.fetchFirstEventsThisWeek()
            let result = try await ClaudeService.shared.analyzeSocialJetlag(
                sleepRecords: sleep,
                calendarEvents: events
            )
            LocalStore.shared.saveSleepRecords(sleep)
            LocalStore.shared.saveSocialJetlagResult(result)
            await MainActor.run {
                self.sleepRecords = sleep
                self.firstEvents = events
                self.result = result
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; self.isLoading = false }
        }
    }
}
