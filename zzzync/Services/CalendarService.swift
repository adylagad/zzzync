import Foundation
import EventKit

final class CalendarService {
    static let shared = CalendarService()
    private let eventStore = EKEventStore()

    private init() {}

    // MARK: - Permissions

    func requestPermissions() async throws {
        if #available(iOS 17.0, *) {
            try await eventStore.requestFullAccessToEvents()
        } else {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error { cont.resume(throwing: error); return }
                    if granted { cont.resume() } else { cont.resume(throwing: CalendarError.denied) }
                }
            }
        }
    }

    // MARK: - Events

    func fetchTodayEvents() -> [CalendarEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return fetchEvents(from: today, to: tomorrow)
    }

    func fetchEvents(days: Int) -> [CalendarEvent] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: days, to: start)!
        return fetchEvents(from: start, to: end)
    }

    func fetchFirstEventsThisWeek() -> [CalendarEvent] {
        // Returns the first event of each day for the past 7 days (for jetlag calculation)
        var result: [CalendarEvent] = []
        for dayOffset in -7...0 {
            let dayStart = Calendar.current.date(byAdding: .day, value: dayOffset, to: Calendar.current.startOfDay(for: Date()))!
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            let dayEvents = fetchEvents(from: dayStart, to: dayEnd).filter { !$0.isAllDay }.sorted { $0.startDate < $1.startDate }
            if let first = dayEvents.first {
                result.append(first)
            }
        }
        return result
    }

    // MARK: - Private

    private func fetchEvents(from start: Date, to end: Date) -> [CalendarEvent] {
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { ek in
            CalendarEvent(
                title: ek.title ?? "Untitled",
                startDate: ek.startDate,
                endDate: ek.endDate,
                isAllDay: ek.isAllDay
            )
        }.sorted { $0.startDate < $1.startDate }
    }
}

enum CalendarError: LocalizedError {
    case denied

    var errorDescription: String? { "Calendar access was denied." }
}
