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
    @State private var swipeOffsets: [UUID: CGFloat] = [:]

    private let deleteThreshold: CGFloat = -80
    private let maxSwipeDistance: CGFloat = -120

    var body: some View {
        VStack(spacing: 0) {
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
                        swipeableRow(habit: habit, isDragged: isDragged)
                            .padding(.vertical, 4)
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
        .alert(
            "Delete \(habitToDelete?.name ?? "habit")?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                guard let habit = habitToDelete else {
                    return
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    swipeOffsets[habit.id] = nil
                    archiveHabit(habit)
                }
                habitToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                cancelDelete()
            }
        } message: {
            Text("This habit will be removed from your daily list. Past completion data is kept.")
        }
    }

    private func swipeableRow(habit: Habit, isDragged: Bool) -> some View {
        let offset = swipeOffsets[habit.id] ?? 0

        return ZStack(alignment: .trailing) {
            if offset < 0 {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.trailing, 20)
                            .opacity(offset < deleteThreshold * 0.4 ? 1 : 0)
                    }
            }

            habitRow(habit: habit, isDragged: isDragged)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 {
                                swipeOffsets[habit.id] = rubberBand(translation)
                            }
                        }
                        .onEnded { _ in
                            if offset < deleteThreshold {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    swipeOffsets[habit.id] = 0
                                }
                                habitToDelete = habit
                                showDeleteConfirmation = true
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    swipeOffsets[habit.id] = 0
                                }
                            }
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func habitRow(habit: Habit, isDragged: Bool) -> some View {
        HStack(spacing: 14) {
            Text(habit.emoji)
                .font(.system(size: 28))

            Text(habit.name)
                .font(.body.weight(.medium))
                .lineLimit(1)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .frame(height: 62)
        .contentShape(Rectangle())
        .dragHandle()
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

    private func cancelDelete() {
        if let habit = habitToDelete {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                swipeOffsets[habit.id] = 0
            }
        }
        habitToDelete = nil
    }

    private func rubberBand(_ translation: CGFloat) -> CGFloat {
        let limit = -maxSwipeDistance
        let absTranslation = min(abs(translation), limit * 3)
        let dampened = limit * (1 - exp(-absTranslation / limit))
        return -dampened
    }

    private func archiveHabit(_ habit: Habit) {
        let service = HabitService(modelContext: modelContext)
        do {
            try service.archiveHabit(habit)
        } catch {}
    }
}
