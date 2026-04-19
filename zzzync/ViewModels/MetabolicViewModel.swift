import Foundation
import Observation

@Observable
final class MetabolicViewModel {
    var foodLogs: [FoodLog] = []
    var isLoggingFood = false
    var error: String?

    func load() {
        foodLogs = LocalStore.shared.loadFoodLogs().reversed()
    }

    func logFood(description: String) async {
        await MainActor.run { isLoggingFood = true; error = nil }
        do {
            let log = try await FoodLogService.shared.logFoodByText(description)
            await MainActor.run {
                self.foodLogs.insert(log, at: 0)
                self.isLoggingFood = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; self.isLoggingFood = false }
        }
    }
}
