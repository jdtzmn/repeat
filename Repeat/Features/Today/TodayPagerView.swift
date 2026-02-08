import Foundation
import Inject
import SwiftUI

struct TodayPagerView: View {
    @ObserveInjection var inject
    let pages: [HabitPagerPage]
    @Binding var selection: Int
    @FocusState.Binding var focusedHabitID: UUID?
    let progressForHabit: (HabitPageEntry) -> CGFloat
    let isAnimatingCompletionForHabit: (HabitPageEntry) -> Bool
    let onHabitSingleTap: () -> Void
    let onHabitDoubleTap: (HabitPageEntry) -> Void
    let onAddDoubleTap: () -> Void

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageView(for: page, at: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.55), value: selection)
        .enableInjection()
    }

    @ViewBuilder
    private func pageView(for page: HabitPagerPage, at _: Int) -> some View {
        switch page {
        case let .habit(entry):
            HabitPageView(
                entry: entry,
                completionProgress: progressForHabit(entry),
                shouldAnimateCompletion: isAnimatingCompletionForHabit(entry),
                focusedHabitID: $focusedHabitID,
                onSingleTap: onHabitSingleTap,
                onDoubleTap: { onHabitDoubleTap(entry) }
            )

        case .add:
            AddHabitPageView(onDoubleTap: onAddDoubleTap)
        }
    }
}
