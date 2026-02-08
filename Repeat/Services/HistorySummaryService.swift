import Foundation
import SwiftData

struct HistorySummaryService {
    let modelContext: ModelContext

    func ensureSummariesUpToDate(todayStart: Date = DayService.todayStart(), now: Date = Date()) throws {
        let normalizedToday = DayService.startOfDay(for: todayStart)

        if let firstCompletionDay = try firstCompletionDay() {
            try refreshSummaries(from: firstCompletionDay, through: normalizedToday, now: now)
            try trimSummaries(validStart: firstCompletionDay, validEnd: normalizedToday)
            return
        }

        try refreshSummary(for: normalizedToday, now: now)
        try trimSummaries(validStart: normalizedToday, validEnd: normalizedToday)
    }

    func refreshSummary(for dayStart: Date, now: Date = Date()) throws {
        let normalizedDay = DayService.startOfDay(for: dayStart)
        let allHabits = try allHabits()
        let completionIDs = try completionIDs(for: normalizedDay)

        let daySummary: DaySummary
        if let existingSummary = try existingSummary(for: normalizedDay) {
            daySummary = existingSummary
        } else {
            daySummary = DaySummary(dayStart: normalizedDay)
            modelContext.insert(daySummary)
        }

        let eligibleIDs = eligibleHabitIDs(on: normalizedDay, from: allHabits)
        daySummary.eligibleHabitCount = eligibleIDs.count
        daySummary.completedHabitCount = completionIDs.intersection(eligibleIDs).count
        daySummary.updatedAt = now
        try modelContext.save()
    }

    func refreshSummaries(
        from startDay: Date,
        through endDay: Date = DayService.todayStart(),
        now: Date = Date()
    ) throws {
        let normalizedStart = DayService.startOfDay(for: startDay)
        let normalizedEnd = DayService.startOfDay(for: endDay)
        guard normalizedStart <= normalizedEnd else {
            return
        }

        let days = DayService.dayStarts(from: normalizedStart, through: normalizedEnd)
        guard !days.isEmpty else {
            return
        }

        let allHabits = try allHabits()
        let completionIDsByDay = try completionIDsByDay(from: normalizedStart, through: normalizedEnd)
        let existingSummaries = try summaries(from: normalizedStart, through: normalizedEnd)
        var summaryByDay = Dictionary(uniqueKeysWithValues: existingSummaries.map { ($0.dayStart, $0) })

        for day in days {
            let eligibleIDs = eligibleHabitIDs(on: day, from: allHabits)
            let completedIDs = completionIDsByDay[day] ?? []

            let summary: DaySummary
            if let existingSummary = summaryByDay[day] {
                summary = existingSummary
            } else {
                summary = DaySummary(dayStart: day)
                modelContext.insert(summary)
                summaryByDay[day] = summary
            }

            summary.eligibleHabitCount = eligibleIDs.count
            summary.completedHabitCount = completedIDs.intersection(eligibleIDs).count
            summary.updatedAt = now
        }

        try modelContext.save()
    }

    private func firstCompletionDay() throws -> Date? {
        var descriptor = FetchDescriptor<HabitCompletion>(sortBy: [SortDescriptor(\HabitCompletion.dayStart)])
        descriptor.fetchLimit = 1
        let completions = try modelContext.fetch(descriptor)
        return completions.first.map { DayService.startOfDay(for: $0.dayStart) }
    }

    private func completionIDs(for dayStart: Date) throws -> Set<UUID> {
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { completion in
                completion.dayStart == dayStart
            }
        )
        let completions = try modelContext.fetch(descriptor)
        return Set(completions.map(\.habitID))
    }

    private func completionIDsByDay(from startDay: Date, through endDay: Date) throws -> [Date: Set<UUID>] {
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { completion in
                completion.dayStart >= startDay && completion.dayStart <= endDay
            }
        )

        var grouped: [Date: Set<UUID>] = [:]
        let completions = try modelContext.fetch(descriptor)
        for completion in completions {
            grouped[completion.dayStart, default: []].insert(completion.habitID)
        }
        return grouped
    }

    private func existingSummary(for dayStart: Date) throws -> DaySummary? {
        let descriptor = FetchDescriptor<DaySummary>(
            predicate: #Predicate { summary in
                summary.dayStart == dayStart
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func summaries(from startDay: Date, through endDay: Date) throws -> [DaySummary] {
        let descriptor = FetchDescriptor<DaySummary>(
            predicate: #Predicate { summary in
                summary.dayStart >= startDay && summary.dayStart <= endDay
            }
        )
        return try modelContext.fetch(descriptor)
    }

    private func trimSummaries(validStart: Date, validEnd: Date) throws {
        let descriptor = FetchDescriptor<DaySummary>()
        let summaries = try modelContext.fetch(descriptor)
        var didDelete = false

        for summary in summaries where summary.dayStart < validStart || summary.dayStart > validEnd {
            modelContext.delete(summary)
            didDelete = true
        }

        if didDelete {
            try modelContext.save()
        }
    }

    private func allHabits() throws -> [Habit] {
        try modelContext.fetch(FetchDescriptor<Habit>())
    }

    private func eligibleHabitIDs(on dayStart: Date, from habits: [Habit]) -> Set<UUID> {
        let normalizedDay = DayService.startOfDay(for: dayStart)
        return Set(habits.compactMap { habit in
            let createdDay = DayService.startOfDay(for: habit.createdAt)
            guard createdDay <= normalizedDay else {
                return nil
            }

            if let archivedAt = habit.archivedAt {
                let archivedDay = DayService.startOfDay(for: archivedAt)
                guard archivedDay >= normalizedDay else {
                    return nil
                }
            }

            return habit.id
        })
    }
}
