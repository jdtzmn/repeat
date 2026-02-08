import Reorderable
import SwiftData
import SwiftUI

struct ManageHabitsPage: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: \Habit.sortOrder
    ) private var habits: [Habit]

    @State private var orderedHabits: [Habit] = []
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Manage Habits")
                .font(.title2.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

            ScrollView {
                ReorderableVStack(
                    orderedHabits,
                    onMove: { from, toIndex in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            orderedHabits.move(
                                fromOffsets: IndexSet(integer: from),
                                toOffset: toIndex > from ? toIndex + 1 : toIndex
                            )
                        }
                        persistOrder()
                    },
                    content: { habit, isDragged in
                        habitRow(habit: habit, isDragged: isDragged)
                    }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .autoScrollOnEdges()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            orderedHabits = habits
        }
        .onChange(of: habits) { _, newValue in
            orderedHabits = newValue
        }
        .confirmationDialog(
            "Delete \(habitToDelete?.name ?? "habit")?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let habit = habitToDelete else {
                    return
                }
                archiveHabit(habit)
                habitToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                habitToDelete = nil
            }
        } message: {
            Text("This habit will be removed from your daily list. Past completion data is kept.")
        }
    }

    private func habitRow(habit: Habit, isDragged: Bool) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .dragHandle()

                Text(habit.emoji)
                    .font(.system(size: 28))

                Text(habit.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                Spacer()
            }

            Button {
                habitToDelete = habit
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(
            color: .black.opacity(isDragged ? 0.14 : 0.03),
            radius: isDragged ? 8 : 2,
            y: isDragged ? 4 : 1
        )
        .scaleEffect(isDragged ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isDragged)
    }

    private func persistOrder() {
        let service = HabitService(modelContext: modelContext)
        do {
            try service.reorderHabits(orderedIDs: orderedHabits.map(\.id))
        } catch {}
    }

    private func archiveHabit(_ habit: Habit) {
        let service = HabitService(modelContext: modelContext)
        do {
            try service.archiveHabit(habit)
        } catch {}
    }
}
