import Foundation

struct SleepRecord: Codable, Identifiable {
    let id: UUID
    let date: Date          // calendar day this session represents
    let bedtime: Date
    let wakeTime: Date
    let durationMinutes: Int
    let deepSleepMinutes: Int
    let remSleepMinutes: Int

    var midpoint: Date {
        bedtime.midpoint(to: wakeTime)
    }

    init(
        id: UUID = UUID(),
        date: Date,
        bedtime: Date,
        wakeTime: Date,
        durationMinutes: Int,
        deepSleepMinutes: Int = 0,
        remSleepMinutes: Int = 0
    ) {
        self.id = id
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.durationMinutes = durationMinutes
        self.deepSleepMinutes = deepSleepMinutes
        self.remSleepMinutes = remSleepMinutes
    }
}
