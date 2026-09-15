//
//  PinCollection.swift
//  Markly
//

import Foundation
import SwiftData

@Model
final class PinCollection {

    // MARK: - Identity

    var id: UUID = UUID()

    // MARK: - Display

    var title: String = ""
    var iconName: String = "pinfill"
    var notes: String = ""

    // MARK: - Ordering

    var sortOrder: Int = 0
    var isPinned: Bool = false

    // MARK: - Timestamps

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Relationships

    @Relationship(deleteRule: .nullify, inverse: \BookmarkItem.pinCollections)
    var bookmarks: [BookmarkItem]? = []

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String = "",
        iconName: String = "pinfill",
        notes: String = "",
        sortOrder: Int = 0,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        bookmarks: [BookmarkItem] = []
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.notes = notes
        self.sortOrder = sortOrder
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bookmarks = bookmarks
    }

    // MARK: - Derived

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Collection" : trimmed
    }

    var bookmarkCount: Int {
        bookmarks?.count ?? 0
    }

    func touch() {
        updatedAt = Date()
    }
}
