import Foundation
import Observation

@Observable
final class ForecastViewModel {
    var forecast: EnergyForecast?
    var emailStressSignals: [EmailStressSignal] = []
    var todayEvents: [CalendarEvent] = []
    var isLoading = false
    var error: String?

    func load() {
        if HackathonDemoScenario.isEnabled {
            HackathonDemoScenario.installFixedDataIfNeeded(force: false)
        }
        forecast = LocalStore.shared.loadEnergyForecast()
        emailStressSignals = LocalStore.shared.loadEmailStressSignals()
        todayEvents = HackathonDemoScenario.isEnabled
            ? HackathonDemoScenario.todayEvents
            : CalendarService.shared.fetchTodayEvents()
        if !HackathonDemoScenario.isEnabled {
            Task { await refreshEmailSignals() }
        }
    }

    func refresh() async {
        if HackathonDemoScenario.isEnabled {
            HackathonDemoScenario.installFixedDataIfNeeded(force: true)
            await MainActor.run {
                self.forecast = LocalStore.shared.loadEnergyForecast()
                self.emailStressSignals = LocalStore.shared.loadEmailStressSignals()
                self.todayEvents = HackathonDemoScenario.todayEvents
                self.error = nil
                self.isLoading = false
            }
            return
        }

        await MainActor.run { isLoading = true; error = nil }
        do {
            let events = CalendarService.shared.fetchTodayEvents()
            let biometrics = try await HealthKitService.shared.fetchBiometrics(days: 3)
            let sleep = try await HealthKitService.shared.fetchSleepRecords(days: 1)
            let emailSignals = try await SupabaseService.shared.fetchEmailStressSignals(days: 7)
            let forecast = try await ClaudeService.shared.generateEnergyForecast(
                todayEvents: events,
                biometrics: biometrics,
                sleepLastNight: sleep.last,
                emailStressSignals: emailSignals
            )
            LocalStore.shared.saveEnergyForecast(forecast)
            LocalStore.shared.saveEmailStressSignals(emailSignals)
            await MainActor.run {
                self.forecast = forecast
                self.emailStressSignals = emailSignals
                self.todayEvents = events
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; self.isLoading = false }
        }
    }

    func refreshEmailSignals() async {
        if HackathonDemoScenario.isEnabled {
            await MainActor.run {
                self.emailStressSignals = LocalStore.shared.loadEmailStressSignals()
            }
            return
        }
        do {
            let signals = try await SupabaseService.shared.fetchEmailStressSignals(days: 7)
            LocalStore.shared.saveEmailStressSignals(signals)
            await MainActor.run { self.emailStressSignals = signals }
        } catch {
            // Non-fatal: email signals are additive to forecast quality.
        }
    }
}
