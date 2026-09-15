//
//  BookmarkItem.swift
//  Markly
//

import Foundation
import SwiftData

@Model
final class BookmarkItem {
    var title: String = ""
    var bookmarkDescription: String = ""
    var link: String = ""
    var tagsRaw: String = ""
    var notes: String = ""
    var isFavorite: Bool = false
    var isPinned: Bool = false
    var isArchived: Bool = false
    var iconData: Data?
    var thumbnailData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship var folder: BookmarkFolder?

    @Relationship(deleteRule: .nullify)
    var pinCollections: [PinCollection]? = []

    @Relationship(deleteRule: .nullify, inverse: \BookmarkNote.bookmark)
    var savedNotes: [BookmarkNote]? = []

    init(
        title: String = "",
        bookmarkDescription: String = "",
        link: String = "",
        tagsRaw: String = "",
        notes: String = "",
        isFavorite: Bool = false,
        isPinned: Bool = false,
        isArchived: Bool = false,
        iconData: Data? = nil,
        thumbnailData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        folder: BookmarkFolder? = nil,
        pinCollections: [PinCollection]? = [],
        savedNotes: [BookmarkNote]? = []
    ) {
        self.title = title
        self.bookmarkDescription = bookmarkDescription
        self.link = link
        self.tagsRaw = tagsRaw
        self.notes = notes
        self.isFavorite = isFavorite
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.iconData = iconData
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folder = folder
        self.pinCollections = pinCollections
        self.savedNotes = savedNotes
    }

    var tags: [String] {
        get {
            tagsRaw
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            tagsRaw = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        }
    }

    var url: String {
        get { link }
        set { link = newValue }
    }

    var normalizedLink: String {
        link.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var hostDisplay: String {
        guard
            let url = URL(string: normalizedWebURLString),
            let host = url.host,
            !host.isEmpty
        else {
            return ""
        }

        return host.replacingOccurrences(of: "www.", with: "")
    }

    var normalizedWebURLString: String {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        } else {
            return "https://\(trimmed)"
        }
    }
}
