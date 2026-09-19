//
//  DictionaryWord.swift
//  Markly
//

import Foundation
import SwiftData

@Model
final class DictionaryWord: Identifiable {
    var id: UUID = UUID()
    var word: String = ""
    var partOfSpeech: String = "Noun"

    // Legacy single-source fields retained for compatibility with existing SwiftData records.
    // New multi-source dictionary functionality uses sourceNames/sourceURLs below.
    var sourceName: String = ""
    var sourceURL: String = ""
    var sourceNames: [String] = []
    var sourceURLs: [String] = []

    var writtenPronunciation: String = ""
    var ipaPronunciation: String = ""
    var synonyms: [String] = []
    var antonyms: [String] = []
    var definitions: [String] = []
    var exampleSentences: [String] = []
    var originEtymology: String = ""
    var relatedWords: [String] = []
    var usageNoteLabels: [String] = []
    var usageNoteValues: [String] = []
    var tags: [String] = []
    var dateAdded: Date = Date()
    var dateModified: Date = Date()

    @Relationship var dictionary: WordDictionary?

    init(
        id: UUID = UUID(),
        word: String,
        partOfSpeech: String = "Noun",
        sourceName: String = "",
        sourceURL: String = "",
        sourceNames: [String] = [],
        sourceURLs: [String] = [],
        writtenPronunciation: String = "",
        ipaPronunciation: String = "",
        synonyms: [String] = [],
        antonyms: [String] = [],
        definitions: [String] = [],
        exampleSentences: [String] = [],
        originEtymology: String = "",
        relatedWords: [String] = [],
        usageNotes: [DictionaryUsageNote] = [],
        tags: [String] = [],
        dateAdded: Date = Date(),
        dateModified: Date = Date(),
        dictionary: WordDictionary? = nil
    ) {
        self.id = id
        self.word = word
        self.partOfSpeech = partOfSpeech
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.sourceNames = sourceNames
        self.sourceURLs = sourceURLs
        self.writtenPronunciation = writtenPronunciation
        self.ipaPronunciation = ipaPronunciation
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.definitions = definitions
        self.exampleSentences = exampleSentences
        self.originEtymology = originEtymology
        self.relatedWords = relatedWords
        self.usageNoteLabels = usageNotes.map(\.label)
        self.usageNoteValues = usageNotes.map(\.value)
        self.tags = tags
        self.dateAdded = dateAdded
        self.dateModified = dateModified
        self.dictionary = dictionary
    }

    var sources: [DictionarySource] {
        get {
            sourceNames.enumerated().compactMap { index, name in
                guard index < sourceURLs.count else { return nil }
                return DictionarySource(name: name, url: sourceURLs[index])
            }
        }
        set {
            sourceNames = newValue.map(\.name)
            sourceURLs = newValue.map(\.url)
        }
    }

    var usageNotes: [DictionaryUsageNote] {
        get {
            usageNoteLabels.enumerated().compactMap { index, label in
                guard index < usageNoteValues.count else { return nil }
                return DictionaryUsageNote(label: label, value: usageNoteValues[index])
            }
        }
        set {
            usageNoteLabels = newValue.map(\.label)
            usageNoteValues = newValue.map(\.value)
        }
    }
}

struct DictionarySource: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var url: String
}

struct DictionaryUsageNote: Identifiable, Hashable {
    var id: UUID = UUID()
    var label: String
    var value: String
}
