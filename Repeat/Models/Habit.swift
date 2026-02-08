import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var sortOrder: Int
    var createdAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String = "New Habit",
        emoji: String = "",
        sortOrder: Int,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}
