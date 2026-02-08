//
//  ContentView.swift
//  Repeat
//
//  Created by Jacob Daitzman on 2/7/26.
//

import Inject
import SwiftData
import SwiftUI

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
    @FocusState private var focusedHabitID: UUID?

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageView(for: page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
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
        .enableInjection()
    }

    @ViewBuilder
    private func pageView(for page: HabitPagerPage) -> some View {
        switch page {
        case let .habit(entry):
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        endEditing()
                    }

                VStack(spacing: 16) {
                    if !entry.habit.emoji.isEmpty {
                        Text(entry.habit.emoji)
                            .font(.system(size: 72))
                    }

                    TextField(
                        "New Habit",
                        text: Binding(
                            get: { entry.habit.name },
                            set: { entry.habit.name = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .focused($focusedHabitID, equals: entry.habit.id)

                    Text(entry.isCompleted ? "Completed today" : "Not completed yet")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                toggleHabit(entry.habit)
            }

        case .add:
            VStack(spacing: 16) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)

                Text("Add New Habit")
                    .font(.title2.weight(.semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                createHabitFromPlusPage()
            }
        }
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

    private func toggleHabit(_ habit: Habit) {
        do {
            let service = HabitService(modelContext: modelContext)
            try service.toggleCompletion(for: habit)
            refreshPages(selectionMode: .specificHabit(habit.id))
        } catch {
            refreshPages(selectionMode: .specificHabit(habit.id))
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
