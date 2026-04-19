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
        sleepRecords = LocalStore.shared.loadSleepRecords()
        firstEvents = CalendarService.shared.fetchFirstEventsThisWeek()
        result = LocalStore.shared.loadSocialJetlagResult()
    }

    func analyze() async {
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
