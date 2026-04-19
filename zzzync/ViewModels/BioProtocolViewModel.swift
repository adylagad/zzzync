import Foundation
import Observation

@Observable
final class BioProtocolViewModel {
    var bioProtocol: BioProtocol?
    var isLoading = false
    var error: String?

    func load() {
        bioProtocol = LocalStore.shared.loadBioProtocol()
    }

    func generate() async {
        await MainActor.run { isLoading = true; error = nil }
        do {
            guard let jetlagResult = LocalStore.shared.loadSocialJetlagResult() else {
                await MainActor.run {
                    self.error = "Run the Social Jetlag analysis first."
                    self.isLoading = false
                }
                return
            }
            let forecast = LocalStore.shared.loadEnergyForecast()
            let foodLogs = LocalStore.shared.loadFoodLogs()

            let proto = try await ClaudeService.shared.generateBioProtocol(
                jetlagResult: jetlagResult,
                forecast: forecast,
                recentFoodLogs: Array(foodLogs.suffix(5))
            )
            LocalStore.shared.saveBioProtocol(proto)
            await MainActor.run {
                self.bioProtocol = proto
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; self.isLoading = false }
        }
    }
}
