import SwiftUI

struct CompletionTransitionView: View {
    let emoji: String
    let completionProgress: CGFloat
    let shouldAnimateCompletion: Bool

    var body: some View {
        ZStack {
            Text(emoji.isEmpty ? "🙂" : emoji)
                .font(.system(size: 72))
                .scaleEffect(max(0.001, 1 - completionProgress))
                .opacity(1 - completionProgress)

            Image(systemName: "checkmark")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(max(0.001, completionProgress))
                .opacity(completionProgress)
        }
        .animation(shouldAnimateCompletion ? .easeInOut(duration: 0.48) : nil, value: completionProgress)
    }
}
