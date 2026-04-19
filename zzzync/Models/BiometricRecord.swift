import Foundation

struct BiometricRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let hrvMs: Double?          // HRV SDNN in milliseconds
    let rhrBpm: Double?         // Resting heart rate
    let activeEnergyKcal: Double?

    init(
        id: UUID = UUID(),
        date: Date,
        hrvMs: Double? = nil,
        rhrBpm: Double? = nil,
        activeEnergyKcal: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.hrvMs = hrvMs
        self.rhrBpm = rhrBpm
        self.activeEnergyKcal = activeEnergyKcal
    }
}
