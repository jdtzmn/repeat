import Foundation
import SwiftUI

struct TodayPagerView: View {
    let pages: [HabitPagerPage]
    @Binding var selection: Int
    @FocusState.Binding var focusedHabitID: UUID?
    let progressForHabit: (HabitPageEntry) -> CGFloat
    let strikethroughDirectionForHabit: (HabitPageEntry) -> StrikethroughDirection
    let onHabitSingleTap: () -> Void
    let onHabitDoubleTap: (HabitPageEntry) -> Void
    let onAddDoubleTap: () -> Void

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageView(for: page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    @ViewBuilder
    private func pageView(for page: HabitPagerPage) -> some View {
        switch page {
        case let .habit(entry):
            HabitPageView(
                entry: entry,
                completionProgress: progressForHabit(entry),
                strikethroughDirection: strikethroughDirectionForHabit(entry),
                focusedHabitID: $focusedHabitID,
                onSingleTap: onHabitSingleTap,
                onDoubleTap: { onHabitDoubleTap(entry) }
            )

        case .add:
            AddHabitPageView(onDoubleTap: onAddDoubleTap)
        }
    }
}
