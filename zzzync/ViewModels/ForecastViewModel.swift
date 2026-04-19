import Foundation
import Observation

@Observable
final class ForecastViewModel {
    var forecast: EnergyForecast?
    var todayEvents: [CalendarEvent] = []
    var isLoading = false
    var error: String?

    func load() {
        forecast = LocalStore.shared.loadEnergyForecast()
        todayEvents = CalendarService.shared.fetchTodayEvents()
    }

    func refresh() async {
        await MainActor.run { isLoading = true; error = nil }
        do {
            let events = CalendarService.shared.fetchTodayEvents()
            let biometrics = try await HealthKitService.shared.fetchBiometrics(days: 3)
            let sleep = try await HealthKitService.shared.fetchSleepRecords(days: 1)
            let forecast = try await ClaudeService.shared.generateEnergyForecast(
                todayEvents: events,
                biometrics: biometrics,
                sleepLastNight: sleep.last
            )
            LocalStore.shared.saveEnergyForecast(forecast)
            await MainActor.run {
                self.forecast = forecast
                self.todayEvents = events
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; self.isLoading = false }
        }
    }
}
