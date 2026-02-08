import SwiftUI

struct CompletionTransitionView: View {
    let emoji: String
    let completionProgress: CGFloat

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
        .animation(.easeInOut(duration: 0.24), value: completionProgress)
    }
}
