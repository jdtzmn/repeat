import Foundation
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query private var summaries: [DaySummary]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(sortedSummaries, id: \.dayStart) { summary in
                historyRow(for: summary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    private var sortedSummaries: [DaySummary] {
        summaries.sorted { $0.dayStart > $1.dayStart }
    }

    private func historyRow(for summary: DaySummary) -> some View {
        let ratio = summary.eligibleHabitCount > 0
            ? CGFloat(summary.completedHabitCount) / CGFloat(summary.eligibleHabitCount)
            : 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(summary.dayStart, format: .dateTime.weekday(.abbreviated).month().day())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(summary.completedHabitCount)/\(summary.eligibleHabitCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: max(0.001, ratio), y: 1, anchor: .leading)
                }
                .frame(height: 20)
        }
    }
}
