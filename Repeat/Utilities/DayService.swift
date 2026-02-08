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

    static func addingDays(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: value, to: date) ?? date
    }

    static func dayStarts(from startDay: Date, through endDay: Date) -> [Date] {
        let normalizedStart = startOfDay(for: startDay)
        let normalizedEnd = startOfDay(for: endDay)
        guard normalizedStart <= normalizedEnd else {
            return []
        }

        var days: [Date] = []
        var cursor = normalizedStart
        while cursor <= normalizedEnd {
            days.append(cursor)
            cursor = addingDays(1, to: cursor)
        }
        return days
    }
}
