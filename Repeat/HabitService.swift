import Foundation
import SwiftData

struct HabitPageEntry {
    let habit: Habit
    let isCompleted: Bool
}

enum HabitPagerPage {
    case habit(HabitPageEntry)
    case add
}

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

    func pagerPages(for dayStart: Date = DayService.todayStart()) throws -> [HabitPagerPage] {
        let habits = try activeHabits()
        let completionSet = Set(try completions(on: dayStart).map(\.habitID))

        let completedPages = habits
            .filter { completionSet.contains($0.id) }
            .map { HabitPagerPage.habit(HabitPageEntry(habit: $0, isCompleted: true)) }

        let incompletePages = habits
            .filter { !completionSet.contains($0.id) }
            .map { HabitPagerPage.habit(HabitPageEntry(habit: $0, isCompleted: false)) }

        return completedPages + incompletePages + [.add]
    }

    func initialPageIndex(for pages: [HabitPagerPage]) -> Int {
        if let firstIncompleteIndex = pages.firstIndex(where: {
            if case let .habit(entry) = $0 {
                return !entry.isCompleted
            }
            return false
        }) {
            return firstIncompleteIndex
        }

        if let firstCompletedIndex = pages.firstIndex(where: {
            if case let .habit(entry) = $0 {
                return entry.isCompleted
            }
            return false
        }) {
            return firstCompletedIndex
        }

        return max(pages.count - 1, 0)
    }

    private func nextSortOrder() throws -> Int {
        var descriptor = FetchDescriptor<Habit>()
        descriptor.sortBy = [SortDescriptor(\Habit.sortOrder, order: .reverse)]
        descriptor.fetchLimit = 1
        let currentMax = try modelContext.fetch(descriptor).first?.sortOrder ?? -1
        return currentMax + 1
    }
}
