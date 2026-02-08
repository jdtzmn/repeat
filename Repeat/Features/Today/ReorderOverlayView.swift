import Reorderable
import SwiftUI

struct ReorderHabitItem: Identifiable {
    let id: UUID
    let emoji: String
    let name: String
}

struct ReorderOverlayView: View {
    let initialItems: [ReorderHabitItem]
    let onDone: (_ orderedIDs: [UUID]) -> Void

    @State private var items: [ReorderHabitItem] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .onTapGesture {
                    onDone(items.map(\.id))
                }

            ScrollView {
                ReorderableVStack(
                    items,
                    onMove: { from, toIndex in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            items.move(
                                fromOffsets: IndexSet(integer: from),
                                toOffset: toIndex > from ? toIndex + 1 : toIndex
                            )
                        }
                    },
                    content: { item, isDragged in
                        reorderRow(item: item, isDragged: isDragged)
                    }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
            .autoScrollOnEdges()
        }
        .onAppear {
            items = initialItems
        }
    }

    private func reorderRow(item: ReorderHabitItem, isDragged: Bool) -> some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.system(size: 28))
                .frame(width: 38)

            Text(item.name)
                .font(.title3.weight(.semibold))
                .lineLimit(1)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .dragHandle()
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(
            color: .black.opacity(isDragged ? 0.18 : 0.04),
            radius: isDragged ? 10 : 2,
            y: isDragged ? 6 : 1
        )
        .scaleEffect(isDragged ? 1.04 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isDragged)
    }
}
