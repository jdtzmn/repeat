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
    @State private var strikethroughDirectionOverrides: [UUID: StrikethroughDirection] = [:]
    @State private var completionHaptics = CompletionHaptics()
    @FocusState private var focusedHabitID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            TodayPagerView(
                pages: pages,
                selection: $selection,
                focusedHabitID: $focusedHabitID,
                progressForHabit: progress(for:),
                strikethroughDirectionForHabit: strikethroughDirection(for:),
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

    private func refreshPages(selectionMode: SelectionMode, animateSelection: Bool = false) {
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
                    setSelection(nextSelection, animated: animateSelection)
                } else {
                    setSelection(service.initialPageIndex(for: pages), animated: animateSelection)
                }

            case .initial:
                setSelection(service.initialPageIndex(for: pages), animated: animateSelection)

            case .keepCurrent:
                if selection >= pages.count {
                    setSelection(max(pages.count - 1, 0), animated: animateSelection)
                }
            }
        } catch {
            pages = [.add]
            selection = 0
        }
    }

    private func toggleHabit(_ entry: HabitPageEntry) {
        completionHaptics.triggerGestureFeedback()

        let currentProgress = progress(for: entry)
        let targetProgress: CGFloat = currentProgress >= 0.5 ? 0 : 1
        let isCompleting = targetProgress > currentProgress
        let direction: StrikethroughDirection = targetProgress > currentProgress ? .forward : .reverse
        let nextIncompleteTarget = isCompleting ? nextIncompleteTarget(excluding: entry.habit.id) : nil

        strikethroughDirectionOverrides[entry.habit.id] = direction
        completionProgressOverrides[entry.habit.id] = currentProgress

        withAnimation(.easeInOut(duration: 0.24)) {
            completionProgressOverrides[entry.habit.id] = targetProgress
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            completionProgressOverrides[entry.habit.id] = nil
            strikethroughDirectionOverrides[entry.habit.id] = nil
        }

        do {
            let service = HabitService(modelContext: modelContext)
            try service.toggleCompletion(for: entry.habit)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                completionHaptics.triggerSettledFeedback()
            }

            if let nextIncompleteTarget {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                    withAnimation(.easeInOut(duration: 0.48)) {
                        selection = nextIncompleteTarget.index
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                        refreshPages(selectionMode: .specificHabit(nextIncompleteTarget.id))
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                    refreshPages(selectionMode: .specificHabit(entry.habit.id), animateSelection: true)
                }
            }
        } catch {
            refreshPages(selectionMode: .specificHabit(entry.habit.id))
        }
    }

    private func nextIncompleteTarget(excluding habitID: UUID) -> (id: UUID, index: Int)? {
        guard pages.indices.contains(selection) else {
            return nil
        }

        for index in (selection + 1) ..< pages.count {
            guard case let .habit(entry) = pages[index] else {
                continue
            }

            if !entry.isCompleted, entry.habit.id != habitID {
                return (entry.habit.id, index)
            }
        }

        return nil
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

    private func strikethroughDirection(for entry: HabitPageEntry) -> StrikethroughDirection {
        strikethroughDirectionOverrides[entry.habit.id] ?? .forward
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

    private func setSelection(_ newSelection: Int, animated: Bool) {
        guard animated else {
            selection = newSelection
            return
        }

        withAnimation(.easeInOut(duration: 0.48)) {
            selection = newSelection
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
