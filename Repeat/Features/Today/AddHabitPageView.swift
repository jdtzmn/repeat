import Inject
import SwiftUI

struct AddHabitPageView: View {
    @ObserveInjection var inject
    @Environment(\.colorScheme) private var colorScheme
    let onDoubleTap: () -> Void

    private var backgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var foregroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 56))
                .foregroundStyle(foregroundColor)

            Text("Add New Habit")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(foregroundColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(backgroundColor)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .enableInjection()
    }
}
