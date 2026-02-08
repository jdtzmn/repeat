import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var habitID: UUID
    var dayStart: Date
    var completedAt: Date

    init(habitID: UUID, dayStart: Date, completedAt: Date = Date()) {
        self.habitID = habitID
        self.dayStart = dayStart
        self.completedAt = completedAt
    }
}
