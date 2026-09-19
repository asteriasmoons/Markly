//
//  WordDictionary.swift
//  Markly
//
//  Container model for the Dictionary feature. A WordDictionary groups
//  DictionaryWord entries, the same way a BookmarkFolder groups
//  BookmarkItems. Shown in the UI simply as a "Dictionary".
//

import Foundation
import SwiftData

@Model
final class WordDictionary {
    var name: String = ""
    var iconName: String = "openbook"
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \DictionaryWord.dictionary)
    var words: [DictionaryWord]? = []

    init(
        name: String = "",
        iconName: String = "openbook",
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var icon: MarklyIcon {
        IconLibrary.all.first { $0.id == iconName } ?? MarklyIcon(iconName)
    }

    var wordCount: Int {
        words?.count ?? 0
    }
}
