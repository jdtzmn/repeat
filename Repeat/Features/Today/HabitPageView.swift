import Foundation
import SwiftUI

enum StrikethroughDirection {
    case forward
    case reverse
}

struct HabitPageView: View {
    let entry: HabitPageEntry
    let completionProgress: CGFloat
    let strikethroughDirection: StrikethroughDirection
    @FocusState.Binding var focusedHabitID: UUID?
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void

    var body: some View {
        ZStack {
            CompletionPageBackground(progress: completionProgress)

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
                    direction: strikethroughDirection,
                    focusedHabitID: $focusedHabitID,
                    habitID: entry.habit.id
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }
}

private struct AnimatedStrikethroughTextField: View {
    @Binding var text: String
    let completionProgress: CGFloat
    let direction: StrikethroughDirection
    @FocusState.Binding var focusedHabitID: UUID?
    let habitID: UUID

    var body: some View {
        TextField("New Habit", text: $text)
            .textFieldStyle(.plain)
            .font(.largeTitle.weight(.semibold))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .focused($focusedHabitID, equals: habitID)
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width * completionProgress
                    let alignment: Alignment = direction == .forward ? .leading : .trailing
                    Rectangle()
                        .fill(Color.primary.opacity(0.6))
                        .frame(width: width, height: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                }
            }
    }
}

private struct CompletionPageBackground: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let diameter = max(geometry.size.width, geometry.size.height) * 2.4
            Circle()
                .fill(Color.accentColor.opacity(0.22))
                .frame(width: diameter, height: diameter)
                .scaleEffect(max(0.001, progress))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .animation(.easeInOut(duration: 0.24), value: progress)
        }
        .allowsHitTesting(false)
    }
}
