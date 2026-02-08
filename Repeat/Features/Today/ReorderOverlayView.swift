import Foundation
import SwiftUI

struct ReorderOverlayView: View {
    private let rowHeight: CGFloat = 86
    private let rowSpacing: CGFloat = 12
    private let edgeThreshold: CGFloat = 110

    let habits: [Habit]
    let initialDraggedHabitID: UUID
    let onCancel: () -> Void
    let onCommit: (_ orderedIDs: [UUID], _ focusedHabitID: UUID) -> Void

    @State private var orderedIDs: [UUID] = []
    @State private var draggedHabitID: UUID?
    @State private var dragStartIndex = 0
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var autoScrollDirection = 0
    @State private var autoScrollTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture {
                        stopAutoScroll()
                        onCancel()
                    }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: rowSpacing) {
                            ForEach(Array(orderedIDs.enumerated()), id: \.element) { index, habitID in
                                if let habit = habits.first(where: { $0.id == habitID }) {
                                    row(for: habit, isDragged: draggedHabitID == habitID)
                                        .id(index)
                                        .offset(y: draggedHabitID == habitID ? dragOffset : 0)
                                        .zIndex(draggedHabitID == habitID ? 100 : 0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: orderedIDs)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 40)
                    }
                    .gesture(dragGesture(in: geometry, proxy: proxy))
                    .overlay(alignment: .topTrailing) {
                        Button("Done") {
                            stopAutoScroll()
                            onCommit(orderedIDs, draggedHabitID ?? initialDraggedHabitID)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(20)
                    }
                }
            }
        }
        .onAppear {
            orderedIDs = habits.map(\.id)
            draggedHabitID = initialDraggedHabitID
            if let startIndex = orderedIDs.firstIndex(of: initialDraggedHabitID) {
                dragStartIndex = startIndex
                currentIndex = startIndex
            }
        }
        .onDisappear {
            stopAutoScroll()
        }
    }

    private func row(for habit: Habit, isDragged: Bool) -> some View {
        HStack(spacing: 14) {
            Text(habit.emoji)
                .font(.system(size: 30))
                .frame(width: 42)

            Text(habit.name)
                .font(.title3.weight(.semibold))
                .lineLimit(1)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: rowHeight)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(isDragged ? 0.15 : 0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isDragged ? 0.18 : 0.04), radius: isDragged ? 14 : 2, y: isDragged ? 8 : 1)
    }

    private func dragGesture(in geometry: GeometryProxy, proxy: ScrollViewProxy) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard draggedHabitID != nil else {
                    return
                }

                let slotHeight = rowHeight + rowSpacing
                let shift = Int(round(value.translation.height / slotHeight))
                let proposedIndex = clamp(dragStartIndex + shift, lower: 0, upper: orderedIDs.count - 1)

                if proposedIndex != currentIndex {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        orderedIDs.move(
                            fromOffsets: IndexSet(integer: currentIndex),
                            toOffset: proposedIndex > currentIndex ? proposedIndex + 1 : proposedIndex
                        )
                    }
                    currentIndex = proposedIndex
                }

                let movedSlots = CGFloat(currentIndex - dragStartIndex)
                dragOffset = value.translation.height - (movedSlots * slotHeight)

                let y = value.location.y
                if y < edgeThreshold {
                    startAutoScroll(direction: -1, proxy: proxy)
                } else if y > geometry.size.height - edgeThreshold {
                    startAutoScroll(direction: 1, proxy: proxy)
                } else {
                    stopAutoScroll()
                }
            }
            .onEnded { _ in
                stopAutoScroll()
                dragStartIndex = currentIndex
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    dragOffset = 0
                }
            }
    }

    private func startAutoScroll(direction: Int, proxy: ScrollViewProxy) {
        guard direction != 0 else {
            stopAutoScroll()
            return
        }

        guard autoScrollDirection != direction else {
            return
        }

        stopAutoScroll()
        autoScrollDirection = direction

        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                let targetIndex = clamp(currentIndex + direction, lower: 0, upper: orderedIDs.count - 1)
                guard targetIndex != currentIndex else {
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    continue
                }

                withAnimation(.easeInOut(duration: 0.12)) {
                    orderedIDs.move(
                        fromOffsets: IndexSet(integer: currentIndex),
                        toOffset: targetIndex > currentIndex ? targetIndex + 1 : targetIndex
                    )
                    currentIndex = targetIndex
                    dragStartIndex = targetIndex
                    dragOffset = 0
                }

                withAnimation(.linear(duration: 0.12)) {
                    proxy.scrollTo(targetIndex, anchor: .center)
                }

                try? await Task.sleep(nanoseconds: 140_000_000)
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
        autoScrollDirection = 0
    }

    private func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
