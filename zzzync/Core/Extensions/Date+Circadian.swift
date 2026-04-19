import Foundation

extension Date {
    /// Hour of day as a fractional Double (e.g. 14.5 = 2:30 PM)
    var fractionalHour: Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }

    /// Returns a Date representing the midpoint between self and another date
    func midpoint(to other: Date) -> Date {
        let interval = other.timeIntervalSince(self)
        return addingTimeInterval(interval / 2)
    }

    /// Strips to just the date component (midnight) in the current calendar
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns a Date set to a given hour (0-23) on the same calendar day as self
    func settingHour(_ hour: Int, minute: Int = 0) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: self)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return Calendar.current.date(from: comps) ?? self
    }

    /// Human-readable time string, e.g. "2:30 AM"
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: self)
    }

    /// Short date string, e.g. "Mon Apr 19"
    var shortDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f.string(from: self)
    }
}

extension Array where Element == Date {
    /// Returns the average of an array of dates as a single Date
    func average() -> Date? {
        guard !isEmpty else { return nil }
        let total = reduce(0.0) { $0 + $1.timeIntervalSinceReferenceDate }
        return Date(timeIntervalSinceReferenceDate: total / Double(count))
    }
}
