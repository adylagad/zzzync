import Foundation

struct CalendarEvent: Codable, Identifiable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    var stressWeight: Double    // 0.0–1.0; Claude-assigned, default 0.5

    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        stressWeight: Double = 0.5
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.stressWeight = stressWeight
    }
}
