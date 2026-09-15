//
//  ReaderArticle.swift
//  Markly
//

import Foundation

struct ReaderArticle: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let byline: String?
    let siteName: String?
    let excerpt: String?
    let sourceURL: URL
    let heroImageURL: URL?
    let publishedDate: Date?
    let language: String?
    let length: Int?
    let estimatedReadingMinutes: Int
    let blocks: [ReaderBlock]
    let plainText: String

    var sourceHost: String {
        sourceURL.host?.replacingOccurrences(of: "www.", with: "") ?? sourceURL.absoluteString
    }
}

enum ReaderBlock: Hashable {
    case heading(level: Int, content: ReaderText)
    case paragraph(ReaderText)
    case image(url: URL, alt: String?, caption: String?)
    case quote(ReaderText)
    case unorderedList([ReaderListItem])
    case orderedList([ReaderListItem])
    case code(language: String?, code: String)
    case divider
    case link(text: ReaderText, url: URL)
}

struct ReaderListItem: Hashable {
    var content: ReaderText
}

struct ReaderText: Hashable {
    var runs: [ReaderTextRun]

    var plainText: String {
        runs.map(\.text).joined()
    }

    var isEmpty: Bool {
        plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ReaderTextRun: Hashable, Codable {
    var text: String
    var isBold: Bool
    var isItalic: Bool
    var isCode: Bool
    var linkURL: URL?

    init(
        text: String,
        isBold: Bool = false,
        isItalic: Bool = false,
        isCode: Bool = false,
        linkURL: URL? = nil
    ) {
        self.text = text
        self.isBold = isBold
        self.isItalic = isItalic
        self.isCode = isCode
        self.linkURL = linkURL
    }
}

