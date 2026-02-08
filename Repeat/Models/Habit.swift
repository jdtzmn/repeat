import Foundation
import SwiftData

@Model
final class Habit {
    static let defaultEmoji = "✅️"

    var id: UUID
    var name: String
    var emoji: String
    var sortOrder: Int
    var createdAt: Date
    var isArchived: Bool
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        name: String = "New Habit",
        emoji: String = Habit.defaultEmoji,
        sortOrder: Int,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.archivedAt = archivedAt
    }

    static func normalizedEmoji(_ value: String) -> String {
        guard let first = value.first else {
            return defaultEmoji
        }
        return String(first)
    }
}
