import Foundation

enum DayService {
    static var calendar: Calendar {
        Calendar.autoupdatingCurrent
    }

    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func todayStart(now: Date = Date()) -> Date {
        startOfDay(for: now)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}
