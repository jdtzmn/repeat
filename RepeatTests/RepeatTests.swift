//
//  RepeatTests.swift
//  RepeatTests
//
//  Created by Jacob Daitzman on 2/7/26.
//

import Testing
import Foundation
import SwiftData
@testable import Repeat

struct RepeatTests {
    @Test func dayServiceNormalizesToStartOfDay() {
        let date = Date(timeIntervalSince1970: 1_738_937_221)
        let start = DayService.startOfDay(for: date)

        #expect(start <= date)
        #expect(DayService.isSameDay(start, date))
    }

    @Test func toggleCompletionIsIdempotent() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let service = HabitService(modelContext: context)
        let habit = Habit(sortOrder: 0)
        context.insert(habit)

        let dayStart = DayService.todayStart(now: Date(timeIntervalSince1970: 1_738_937_221))

        let firstToggleResult = try service.toggleCompletion(for: habit, dayStart: dayStart)
        let completionsAfterFirst = try service.completions(on: dayStart)

        #expect(firstToggleResult)
        #expect(completionsAfterFirst.count == 1)

        let secondToggleResult = try service.toggleCompletion(for: habit, dayStart: dayStart)
        let completionsAfterSecond = try service.completions(on: dayStart)

        #expect(!secondToggleResult)
        #expect(completionsAfterSecond.isEmpty)
    }

    @Test func pagerOrderingAndInitialIndexRules() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let service = HabitService(modelContext: context)

        let firstHabit = Habit(name: "First", sortOrder: 0)
        let secondHabit = Habit(name: "Second", sortOrder: 1)
        context.insert(firstHabit)
        context.insert(secondHabit)

        let dayStart = DayService.todayStart(now: Date(timeIntervalSince1970: 1_738_937_221))
        context.insert(HabitCompletion(habitID: secondHabit.id, dayStart: dayStart))

        let pages = try service.pagerPages(for: dayStart)
        #expect(pages.count == 3)

        if case let .habit(firstEntry) = pages[0] {
            #expect(firstEntry.habit.id == secondHabit.id)
            #expect(firstEntry.isCompleted)
        } else {
            Issue.record("Expected first pager entry to be a habit page")
        }

        if case let .habit(secondEntry) = pages[1] {
            #expect(secondEntry.habit.id == firstHabit.id)
            #expect(!secondEntry.isCompleted)
        } else {
            Issue.record("Expected second pager entry to be a habit page")
        }

        if case .add = pages[2] {
            #expect(true)
        } else {
            Issue.record("Expected trailing add page")
        }

        let initialIndexWithIncomplete = service.initialPageIndex(for: pages)
        #expect(initialIndexWithIncomplete == 1)

        try service.toggleCompletion(for: firstHabit, dayStart: dayStart)
        let allCompletedPages = try service.pagerPages(for: dayStart)
        let initialIndexAllCompleted = service.initialPageIndex(for: allCompletedPages)
        #expect(initialIndexAllCompleted == 0)

        let emptyContainer = try makeInMemoryContainer()
        let emptyService = HabitService(modelContext: ModelContext(emptyContainer))
        let emptyPages = try emptyService.pagerPages(for: dayStart)
        #expect(emptyPages.count == 1)
        #expect(emptyService.initialPageIndex(for: emptyPages) == 0)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
