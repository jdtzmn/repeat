import ElegantEmojiPicker
import Foundation
import Inject
import SwiftUI

struct HabitPageView: View {
    @ObserveInjection var inject
    let entry: HabitPageEntry
    let completionProgress: CGFloat
    let shouldAnimateCompletion: Bool
    @FocusState.Binding var focusedHabitID: UUID?
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void

    @State private var isEmojiPickerPresented = false
    @State private var selectedEmoji: Emoji?

    var body: some View {
        ZStack {
            CompletionPageBackground(
                progress: completionProgress,
                shouldAnimateCompletion: shouldAnimateCompletion
            )

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onSingleTap()
                }

            VStack(spacing: 16) {
                Button {
                    onSingleTap()
                    isEmojiPickerPresented = true
                } label: {
                    CompletionTransitionView(
                        emoji: entry.habit.emoji,
                        completionProgress: completionProgress,
                        shouldAnimateCompletion: shouldAnimateCompletion
                    )
                }
                .buttonStyle(.plain)

                AnimatedStrikethroughTextField(
                    text: Binding(
                        get: { entry.habit.name },
                        set: { entry.habit.name = $0 }
                    ),
                    completionProgress: completionProgress,
                    shouldAnimateCompletion: shouldAnimateCompletion,
                    focusedHabitID: $focusedHabitID,
                    habitID: entry.habit.id
                )
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .emojiPicker(
            isPresented: $isEmojiPickerPresented,
            selectedEmoji: $selectedEmoji,
            configuration: ElegantConfiguration(showSearch: true, showRandom: false, showReset: false)
        )
        .onChange(of: selectedEmoji) { _, newValue in
            guard let emojiValue = newValue?.emoji else {
                return
            }
            entry.habit.emoji = Habit.normalizedEmoji(emojiValue)
        }
        .enableInjection()
    }
}

private struct AnimatedStrikethroughTextField: View {
    @Binding var text: String
    let completionProgress: CGFloat
    let shouldAnimateCompletion: Bool
    @FocusState.Binding var focusedHabitID: UUID?
    let habitID: UUID
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TextField("New Habit", text: $text)
            .textFieldStyle(.plain)
            .font(.largeTitle.weight(.semibold))
            .foregroundStyle(textColor(for: completionProgress))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .focused($focusedHabitID, equals: habitID)
            .overlay {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 2)
                    .scaleEffect(x: max(0.001, completionProgress), y: 1, anchor: .leading)
                    .animation(shouldAnimateCompletion ? .easeInOut(duration: 0.48) : nil, value: completionProgress)
            }
    }

    private func textColor(for progress: CGFloat) -> Color {
        let clampedProgress = min(max(progress, 0), 1)
        let startValue: CGFloat = colorScheme == .dark ? 1 : 0
        let blendedValue = startValue + (1 - startValue) * clampedProgress
        return Color(red: blendedValue, green: blendedValue, blue: blendedValue)
    }
}

private struct CompletionPageBackground: View {
    let progress: CGFloat
    let shouldAnimateCompletion: Bool

    var body: some View {
        GeometryReader { geometry in
            let diameter = max(geometry.size.width, geometry.size.height) * 2.4
            Circle()
                .fill(Color.accentColor.opacity(1.0))
                .frame(width: diameter, height: diameter)
                .scaleEffect(max(0.001, progress))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .animation(shouldAnimateCompletion ? .easeInOut(duration: 0.48) : nil, value: progress)
        }
        .ignoresSafeArea(.container, edges: .vertical)
        .allowsHitTesting(false)
    }
}
