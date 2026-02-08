import SwiftUI

struct EmojiPickerView: View {
    private let emojiOptions = [
        "✅️", "🙂", "😀", "😄", "😁", "😌", "😍", "🤩", "🥳",
        "💪", "🏃", "🧘", "📚", "🧼", "🛏️", "🧹", "🧺",
        "💧", "🥗", "🍎", "☕", "📝", "🎯", "🌱",
    ]

    let onSelect: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 54, maximum: 72), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button {
                            onSelect(emoji)
                        } label: {
                            Text(emoji)
                                .font(.system(size: 34))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Pick Emoji")
        }
    }
}
