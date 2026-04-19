import Foundation
import UIKit

final class FoodLogService {
    static let shared = FoodLogService()
    private init() {}

    /// Converts a UIImage to base64 JPEG and creates a FoodLog with Claude Vision audit.
    func logFood(image: UIImage, textDescription: String = "") async throws -> FoodLog {
        let jpeg = image.jpegData(compressionQuality: Constants.foodPhotoJPEGQuality)
        let base64 = jpeg?.base64EncodedString()

        let description = textDescription.isEmpty ? "Food item from photo" : textDescription
        var log = FoodLog(
            timestamp: Date(),
            description: description,
            imageData: jpeg
        )

        let biometrics = LocalStore.shared.loadBiometrics()
        let audit = try await ClaudeService.shared.auditFoodLog(
            foodLog: log,
            recentBiometrics: biometrics,
            imageBase64: base64
        )
        log.auditResult = audit

        LocalStore.shared.appendFoodLog(log)
        return log
    }

    /// Log food by text description only (no photo).
    func logFoodByText(_ text: String) async throws -> FoodLog {
        var log = FoodLog(timestamp: Date(), description: text)
        let biometrics = LocalStore.shared.loadBiometrics()
        let audit = try await ClaudeService.shared.auditFoodLog(
            foodLog: log,
            recentBiometrics: biometrics
        )
        log.auditResult = audit
        LocalStore.shared.appendFoodLog(log)
        return log
    }
}
