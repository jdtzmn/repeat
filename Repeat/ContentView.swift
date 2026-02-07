//
//  ContentView.swift
//  Repeat
//
//  Created by Jacob Daitzman on 2/7/26.
//

import SwiftUI
import SwiftData
import Inject

struct ContentView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    @State private var pages: [HabitPagerPage] = [.add]
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageView(for: page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .task {
            refreshPages()
        }
        .onChange(of: habits.count) { _, _ in
            refreshPages()
        }
        .onChange(of: completions.count) { _, _ in
            refreshPages()
        }
        .enableInjection()
    }

    @ViewBuilder
    private func pageView(for page: HabitPagerPage) -> some View {
        switch page {
        case let .habit(entry):
            VStack(spacing: 16) {
                if !entry.habit.emoji.isEmpty {
                    Text(entry.habit.emoji)
                        .font(.system(size: 72))
                }

                Text(entry.habit.name)
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(entry.isCompleted ? "Completed today" : "Not completed yet")
                    .foregroundStyle(.secondary)
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
        }
    }

    private func refreshPages() {
        refreshPages(selecting: nil)
    }

    private func refreshPages(selecting habitID: UUID?) {
        let service = HabitService(modelContext: modelContext)
        do {
            pages = try service.pagerPages()
            if let habitID,
               let nextSelection = pages.firstIndex(where: {
                   if case let .habit(entry) = $0 {
                       return entry.habit.id == habitID
                   }
                   return false
               }) {
                selection = nextSelection
                return
            }

            if selection >= pages.count {
                selection = max(pages.count - 1, 0)
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
            refreshPages(selecting: habit.id)
        } catch {
            refreshPages(selecting: habit.id)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
