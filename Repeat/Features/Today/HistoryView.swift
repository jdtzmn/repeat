import Inject
import SwiftData
import SwiftUI

struct HistoryView: View {
    @ObserveInjection var inject
    @Query private var summaries: [DaySummary]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(sortedSummaries, id: \.dayStart) { summary in
                historyRow(for: summary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .enableInjection()
    }

    private var sortedSummaries: [DaySummary] {
        summaries.sorted { $0.dayStart > $1.dayStart }
    }

    private func historyRow(for summary: DaySummary) -> some View {
        let ratio = summary.eligibleHabitCount > 0
            ? CGFloat(summary.completedHabitCount) / CGFloat(summary.eligibleHabitCount)
            : 0

        return Rectangle()
            .fill(Color.primary.opacity(0.08))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: max(0.001, ratio), y: 1, anchor: .leading)
            }
            .frame(height: 14)
        }
}
