import Foundation
import SwiftData

@Model
final class DaySummary {
    var dayStart: Date
    var eligibleHabitCount: Int
    var completedHabitCount: Int
    var updatedAt: Date

    init(
        dayStart: Date,
        eligibleHabitCount: Int = 0,
        completedHabitCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.dayStart = Calendar.autoupdatingCurrent.startOfDay(for: dayStart)
        self.eligibleHabitCount = eligibleHabitCount
        self.completedHabitCount = completedHabitCount
        self.updatedAt = updatedAt
    }
}
