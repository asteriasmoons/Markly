//
//  BookmarkNote.swift
//  Markly
//

import Foundation
import SwiftData

@Model
final class BookmarkNote {
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship var bookmark: BookmarkItem?

    init(
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        bookmark: BookmarkItem? = nil
    ) {
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bookmark = bookmark
    }
}
