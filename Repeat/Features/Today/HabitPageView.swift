import Foundation
import SwiftUI

struct HabitPageView: View {
    let entry: HabitPageEntry
    let completionProgress: CGFloat
    @FocusState.Binding var focusedHabitID: UUID?
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onSingleTap()
                }

            VStack(spacing: 16) {
                CompletionTransitionView(
                    emoji: entry.habit.emoji,
                    completionProgress: completionProgress
                )

                AnimatedStrikethroughTextField(
                    text: Binding(
                        get: { entry.habit.name },
                        set: { entry.habit.name = $0 }
                    ),
                    completionProgress: completionProgress,
                    focusedHabitID: $focusedHabitID,
                    habitID: entry.habit.id
                )

                Text(completionProgress >= 0.5 ? "Completed today" : "Not completed yet")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }
}

private struct AnimatedStrikethroughTextField: View {
    @Binding var text: String
    let completionProgress: CGFloat
    @FocusState.Binding var focusedHabitID: UUID?
    let habitID: UUID

    var body: some View {
        TextField("New Habit", text: $text)
            .textFieldStyle(.plain)
            .font(.largeTitle.weight(.semibold))
            .multilineTextAlignment(.center)
            .focused($focusedHabitID, equals: habitID)
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width * completionProgress
                    Rectangle()
                        .fill(Color.primary.opacity(0.6))
                        .frame(width: width, height: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
    }
}
