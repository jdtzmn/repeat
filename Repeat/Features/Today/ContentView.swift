//
//  ContentView.swift
//  Repeat
//
//  Created by Jacob Daitzman on 2/7/26.
//

import Inject
import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    private enum SelectionMode {
        case keepCurrent
        case specificHabit(UUID)
        case initial
    }

    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    @State private var pages: [HabitPagerPage] = [.add]
    @State private var selection = 0
    @State private var pendingFocusHabitID: UUID?
    @State private var completionProgressOverrides: [UUID: CGFloat] = [:]
    @FocusState private var focusedHabitID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            TodayPagerView(
                pages: pages,
                selection: $selection,
                focusedHabitID: $focusedHabitID,
                progressForHabit: progress(for:),
                onHabitSingleTap: endEditing,
                onHabitDoubleTap: toggleHabit,
                onAddDoubleTap: createHabitFromPlusPage
            )

            TodayHistoryView()
        }
        .task {
            refreshPages(selectionMode: .initial)
        }
        .onChange(of: habits.count) { _, _ in
            refreshPages()
        }
        .onChange(of: completions.count) { _, _ in
            refreshPages()
        }
        .onChange(of: selection) { _, _ in
            endEditing()
            focusPendingHabitIfNeeded()
        }
        .onChange(of: focusedHabitID) { _, newValue in
            guard newValue != nil else {
                return
            }
            selectAllFocusedText()
        }
        .enableInjection()
    }

    private func refreshPages() {
        refreshPages(selectionMode: .keepCurrent)
    }

    private func refreshPages(selectionMode: SelectionMode) {
        let service = HabitService(modelContext: modelContext)
        do {
            pages = try service.pagerPages()

            switch selectionMode {
            case let .specificHabit(habitID):
                if let nextSelection = pages.firstIndex(where: {
                    if case let .habit(entry) = $0 {
                        return entry.habit.id == habitID
                    }
                    return false
                }) {
                    selection = nextSelection
                } else {
                    selection = service.initialPageIndex(for: pages)
                }

            case .initial:
                selection = service.initialPageIndex(for: pages)

            case .keepCurrent:
                if selection >= pages.count {
                    selection = max(pages.count - 1, 0)
                }
            }
        } catch {
            pages = [.add]
            selection = 0
        }
    }

    private func toggleHabit(_ entry: HabitPageEntry) {
        let currentProgress = progress(for: entry)
        let targetProgress: CGFloat = currentProgress >= 0.5 ? 0 : 1
        completionProgressOverrides[entry.habit.id] = currentProgress

        withAnimation(.easeInOut(duration: 0.24)) {
            completionProgressOverrides[entry.habit.id] = targetProgress
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            completionProgressOverrides[entry.habit.id] = nil
        }

        do {
            let service = HabitService(modelContext: modelContext)
            try service.toggleCompletion(for: entry.habit)
            refreshPages(selectionMode: .specificHabit(entry.habit.id))
        } catch {
            refreshPages(selectionMode: .specificHabit(entry.habit.id))
        }
    }

    private func createHabitFromPlusPage() {
        do {
            let service = HabitService(modelContext: modelContext)
            let habit = try service.createHabit(name: "New Habit")
            refreshPages(selectionMode: .specificHabit(habit.id))
            pendingFocusHabitID = habit.id
            focusPendingHabitIfNeeded()
        } catch {
            refreshPages()
        }
    }

    private func focusPendingHabitIfNeeded() {
        guard let pendingFocusHabitID else {
            return
        }

        guard pages.indices.contains(selection) else {
            return
        }

        if case let .habit(entry) = pages[selection], entry.habit.id == pendingFocusHabitID {
            focusedHabitID = pendingFocusHabitID
            self.pendingFocusHabitID = nil
        }
    }

    private func selectAllFocusedText() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
        }
    }

    private func progress(for entry: HabitPageEntry) -> CGFloat {
        completionProgressOverrides[entry.habit.id] ?? (entry.isCompleted ? 1 : 0)
    }

    private func endEditing() {
        guard focusedHabitID != nil else {
            return
        }

        focusedHabitID = nil
        do {
            try modelContext.save()
        } catch {}
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
