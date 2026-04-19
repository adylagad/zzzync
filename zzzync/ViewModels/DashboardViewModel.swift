import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var jetlagResult: SocialJetlagResult?
    var forecast: EnergyForecast?
    var recentFoodLogs: [FoodLog] = []
    var isLoading = false
    var error: String?

    var syncScore: Int { jetlagResult?.score ?? 0 }

    func loadCachedData() {
        jetlagResult = LocalStore.shared.loadSocialJetlagResult()
        forecast = LocalStore.shared.loadEnergyForecast()
        recentFoodLogs = Array(LocalStore.shared.loadFoodLogs().suffix(3))
    }

    func refresh() async {
        await MainActor.run { isLoading = true; error = nil }

        do {
            // Fetch fresh data
            let sleepRecords = try await HealthKitService.shared.fetchSleepRecords()
            let biometrics = try await HealthKitService.shared.fetchBiometrics()
            let todayEvents = CalendarService.shared.fetchTodayEvents()
            let weekEvents = CalendarService.shared.fetchEvents(days: 7)

            LocalStore.shared.saveSleepRecords(sleepRecords)
            LocalStore.shared.saveBiometrics(biometrics)

            // Run analyses in parallel
            async let jetlag = ClaudeService.shared.analyzeSocialJetlag(
                sleepRecords: sleepRecords,
                calendarEvents: weekEvents
            )
            async let energyForecast = ClaudeService.shared.generateEnergyForecast(
                todayEvents: todayEvents,
                biometrics: biometrics,
                sleepLastNight: sleepRecords.last
            )

            let (j, f) = try await (jetlag, energyForecast)

            LocalStore.shared.saveSocialJetlagResult(j)
            LocalStore.shared.saveEnergyForecast(f)

            await MainActor.run {
                self.jetlagResult = j
                self.forecast = f
                self.recentFoodLogs = Array(LocalStore.shared.loadFoodLogs().suffix(3))
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
