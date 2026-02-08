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
    private let completionAnimationDuration: TimeInterval = 0.48
    private let pageAdvanceDuration: TimeInterval = 0.55

    private enum SelectionMode {
        case keepCurrent
        case specificHabit(UUID)
        case initial
    }

    private enum VerticalPage: Int {
        case manage = 0
        case today = 1
    }

    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    @State private var pages: [HabitPagerPage] = [.add]
    @State private var selection = 0
    @State private var verticalPage: VerticalPage? = .today
    @State private var pendingFocusHabitID: UUID?
    @State private var completionProgressOverrides: [UUID: CGFloat] = [:]
    @State private var isCompletionAnimationInFlight = false
    @State private var toggleFlowTask: Task<Void, Never>?
    @State private var completionHaptics = CompletionHaptics()
    @State private var todayPagerReloadToken = UUID()
    @FocusState private var focusedHabitID: UUID?

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ManageHabitsPage()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(VerticalPage.manage)

                    todayContent
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(VerticalPage.today)
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $verticalPage)
            .defaultScrollAnchor(.bottom)
        }
        .task {
            ensureHabitEmojis()
            refreshPages(selectionMode: .initial)
        }
        .onChange(of: habits) { _, _ in
            ensureHabitEmojis()
            guard !isCompletionAnimationInFlight else {
                return
            }
            refreshPages()
        }
        .onChange(of: completions.count) { _, _ in
            guard !isCompletionAnimationInFlight else {
                return
            }
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
        .onChange(of: verticalPage) { _, newValue in
            if newValue == .today {
                refreshPages(selectionMode: .initial)
                todayPagerReloadToken = UUID()
            }
        }
        .onDisappear {
            toggleFlowTask?.cancel()
            toggleFlowTask = nil
        }
        .enableInjection()
    }

    private var todayContent: some View {
        VStack(spacing: 0) {
            TodayPagerView(
                pages: pages,
                selection: $selection,
                focusedHabitID: $focusedHabitID,
                progressForHabit: progress(for:),
                isAnimatingCompletionForHabit: isAnimatingCompletion(for:),
                onHabitSingleTap: endEditing,
                onHabitDoubleTap: toggleHabit,
                onAddDoubleTap: createHabitFromPlusPage
            )
            .id(todayPagerReloadToken)

            TodayHistoryView()
        }
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
        guard !isCompletionAnimationInFlight, verticalPage == .today else {
            return
        }

        toggleFlowTask?.cancel()
        toggleFlowTask = Task { @MainActor in
            await runToggleFlow(for: entry)
        }
    }

    @MainActor
    private func runToggleFlow(for entry: HabitPageEntry) async {
        completionHaptics.triggerGestureFeedback()

        let habitID = entry.habit.id
        defer {
            completionProgressOverrides[habitID] = nil
            isCompletionAnimationInFlight = false
            toggleFlowTask = nil
        }

        let currentProgress = progress(for: entry)
        let targetProgress: CGFloat = currentProgress >= 0.5 ? 0 : 1
        let isCompleting = targetProgress > currentProgress
        let nextIncompleteTarget = isCompleting ? nextIncompleteTarget(excluding: habitID) : nil
        let originalSelection = selection

        isCompletionAnimationInFlight = true
        completionProgressOverrides[habitID] = currentProgress

        withAnimation(.easeInOut(duration: completionAnimationDuration)) {
            completionProgressOverrides[habitID] = targetProgress
        }

        if await sleep(seconds: completionAnimationDuration + 0.02) {
            return
        }

        var didAutoAdvance = false

        if let nextIncompleteTarget {
            completionHaptics.triggerSettledFeedback()
            withAnimation(.easeInOut(duration: pageAdvanceDuration)) {
                selection = nextIncompleteTarget.index
            }
            didAutoAdvance = true

            if await sleep(seconds: pageAdvanceDuration + 0.08) {
                return
            }
        }

        let service = HabitService(modelContext: modelContext)
        do {
            try service.toggleCompletion(for: entry.habit)
            if !didAutoAdvance {
                completionHaptics.triggerSettledFeedback()
            }
        } catch {
            withAnimation(.easeInOut(duration: completionAnimationDuration * 0.7)) {
                completionProgressOverrides[habitID] = currentProgress
            }
            if didAutoAdvance {
                withAnimation(.easeInOut(duration: pageAdvanceDuration * 0.85)) {
                    selection = originalSelection
                }
            }
            refreshPages(selectionMode: .specificHabit(habitID))
            return
        }

        refreshPages(selectionMode: .keepCurrent)
    }

    @MainActor
    private func sleep(seconds: TimeInterval) async -> Bool {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        do {
            try await Task.sleep(nanoseconds: nanoseconds)
            return Task.isCancelled
        } catch {
            return true
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
        guard verticalPage == .today else {
            return
        }

        do {
            let service = HabitService(modelContext: modelContext)
            let habit = try service.createHabit(name: "New Habit", emoji: Habit.defaultEmoji)
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

    private func isAnimatingCompletion(for entry: HabitPageEntry) -> Bool {
        completionProgressOverrides[entry.habit.id] != nil
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

    private func ensureHabitEmojis() {
        var didMutate = false
        for habit in habits {
            let normalized = Habit.normalizedEmoji(habit.emoji)
            if habit.emoji != normalized {
                habit.emoji = normalized
                didMutate = true
            }
        }

        guard didMutate else {
            return
        }

        do {
            try modelContext.save()
        } catch {}
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
