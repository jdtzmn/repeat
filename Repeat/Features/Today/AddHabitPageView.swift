import SwiftUI

struct AddHabitPageView: View {
    let onDoubleTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("Add New Habit")
                .font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }
}
