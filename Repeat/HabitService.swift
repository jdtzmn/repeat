import Foundation
import SwiftData

struct HabitService {
    let modelContext: ModelContext

    func createHabit(name: String = "New Habit", emoji: String = "") throws -> Habit {
        let habit = Habit(name: name, emoji: emoji, sortOrder: try nextSortOrder())
        modelContext.insert(habit)
        try modelContext.save()
        return habit
    }

    func activeHabits() throws -> [Habit] {
        var descriptor = FetchDescriptor<Habit>(predicate: #Predicate { !$0.isArchived })
        descriptor.sortBy = [SortDescriptor(\Habit.sortOrder)]
        return try modelContext.fetch(descriptor)
    }

    func completions(on dayStart: Date) throws -> [HabitCompletion] {
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.dayStart == dayStart }
        )
        return try modelContext.fetch(descriptor)
    }

    func completion(for habitID: UUID, dayStart: Date) throws -> HabitCompletion? {
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { completion in
                completion.habitID == habitID && completion.dayStart == dayStart
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    @discardableResult
    func toggleCompletion(for habit: Habit, dayStart: Date = DayService.todayStart()) throws -> Bool {
        if let existing = try completion(for: habit.id, dayStart: dayStart) {
            modelContext.delete(existing)
            try modelContext.save()
            return false
        }

        modelContext.insert(HabitCompletion(habitID: habit.id, dayStart: dayStart))
        try modelContext.save()
        return true
    }

    private func nextSortOrder() throws -> Int {
        var descriptor = FetchDescriptor<Habit>()
        descriptor.sortBy = [SortDescriptor(\Habit.sortOrder, order: .reverse)]
        descriptor.fetchLimit = 1
        let currentMax = try modelContext.fetch(descriptor).first?.sortOrder ?? -1
        return currentMax + 1
    }
}
