//
//  ReaderHTMLParser.swift
//  Markly
//

import Foundation

struct ReaderExtractionPayload: Decodable {
    var title: String?
    var byline: String?
    var siteName: String?
    var excerpt: String?
    var sourceURL: String?
    var heroImageURL: String?
    var publishedTime: String?
    var language: String?
    var length: Int?
    var textContent: String?
    var content: String?
    var blocks: [ReaderBlockPayload]
}

struct ReaderBlockPayload: Decodable {
    var type: String
    var level: Int?
    var text: [ReaderTextRunPayload]?
    var url: String?
    var alt: String?
    var caption: String?
    var items: [[ReaderTextRunPayload]]?
    var language: String?
    var code: String?
}

struct ReaderTextRunPayload: Decodable {
    var text: String
    var bold: Bool?
    var italic: Bool?
    var code: Bool?
    var href: String?
}

enum ReaderParseError: Error {
    case unsupported
}

enum ReaderHTMLParser {
    static func makeArticle(from payload: ReaderExtractionPayload, sourceURL: URL) throws -> ReaderArticle {
        let blocks = payload.blocks.compactMap { block(from: $0, baseURL: sourceURL) }
        let fallbackText = payload.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = normalized(payload.title) ?? sourceURL.host?.replacingOccurrences(of: "www.", with: "") ?? "Reader"

        guard !blocks.isEmpty, meaningfulTextCount(blocks: blocks, fallbackText: fallbackText) >= 80 else {
            throw ReaderParseError.unsupported
        }

        let articleText = fallbackText.isEmpty ? blocks.map(blockPlainText).joined(separator: "\n\n") : fallbackText
        let minutes = estimatedReadingMinutes(for: articleText)

        return ReaderArticle(
            title: title,
            byline: normalized(payload.byline),
            siteName: normalized(payload.siteName),
            excerpt: normalized(payload.excerpt),
            sourceURL: sourceURL,
            heroImageURL: resolvedURL(payload.heroImageURL, baseURL: sourceURL),
            publishedDate: date(from: payload.publishedTime),
            language: normalized(payload.language),
            length: payload.length,
            estimatedReadingMinutes: minutes,
            blocks: blocks,
            plainText: articleText
        )
    }

    private static func block(from payload: ReaderBlockPayload, baseURL: URL) -> ReaderBlock? {
        switch payload.type {
        case "heading":
            let text = readerText(from: payload.text, baseURL: baseURL)
            guard !text.isEmpty else { return nil }
            return .heading(level: payload.level ?? 2, content: text)
        case "paragraph":
            let text = readerText(from: payload.text, baseURL: baseURL)
            guard !text.isEmpty else { return nil }
            return .paragraph(text)
        case "image":
            guard let url = resolvedURL(payload.url, baseURL: baseURL) else { return nil }
            return .image(
                url: url,
                alt: normalized(payload.alt),
                caption: normalized(payload.caption)
            )
        case "quote":
            let text = readerText(from: payload.text, baseURL: baseURL)
            guard !text.isEmpty else { return nil }
            return .quote(text)
        case "unorderedList":
            let items = listItems(from: payload.items, baseURL: baseURL)
            guard !items.isEmpty else { return nil }
            return .unorderedList(items)
        case "orderedList":
            let items = listItems(from: payload.items, baseURL: baseURL)
            guard !items.isEmpty else { return nil }
            return .orderedList(items)
        case "code":
            guard let code = normalized(payload.code), !code.isEmpty else { return nil }
            return .code(language: normalized(payload.language), code: code)
        case "divider":
            return .divider
        case "link":
            let text = readerText(from: payload.text, baseURL: baseURL)
            guard !text.isEmpty, let url = resolvedURL(payload.url, baseURL: baseURL) else { return nil }
            return .link(text: text, url: url)
        default:
            return nil
        }
    }

    private static func readerText(from runs: [ReaderTextRunPayload]?, baseURL: URL) -> ReaderText {
        let mapped = (runs ?? []).compactMap { run -> ReaderTextRun? in
            guard !run.text.isEmpty else { return nil }

            return ReaderTextRun(
                text: run.text,
                isBold: run.bold ?? false,
                isItalic: run.italic ?? false,
                isCode: run.code ?? false,
                linkURL: resolvedURL(run.href, baseURL: baseURL)
            )
        }

        return ReaderText(runs: normalizedOrderedMarkerSpacing(in: mapped))
    }

    private static func listItems(from payload: [[ReaderTextRunPayload]]?, baseURL: URL) -> [ReaderListItem] {
        (payload ?? [])
            .map { readerText(from: $0, baseURL: baseURL) }
            .filter { !$0.isEmpty }
            .map { ReaderListItem(content: $0) }
    }

    private static func normalizedOrderedMarkerSpacing(in runs: [ReaderTextRun]) -> [ReaderTextRun] {
        guard let markerIndex = runs.firstIndex(where: { !$0.text.isEmpty }) else { return runs }

        var normalizedRuns = runs
        var markerRun = normalizedRuns[markerIndex]
        var markerText = markerRun.text
        var index = markerText.startIndex

        while index < markerText.endIndex, markerText[index].isWhitespace {
            index = markerText.index(after: index)
        }

        let numberStart = index
        while index < markerText.endIndex, markerText[index].isNumber {
            index = markerText.index(after: index)
        }

        guard numberStart < index, index < markerText.endIndex, markerText[index] == "." else {
            return runs
        }

        let afterPeriod = markerText.index(after: index)
        if afterPeriod == markerText.endIndex {
            if let nextRunStart = nextRunStart(after: markerIndex, in: normalizedRuns), nextRunStart.startsWithLetter {
                if nextRunStart.startsWithWhitespace {
                    normalizeLeadingWhitespace(in: nextRunStart, runs: &normalizedRuns)
                } else {
                    markerText.append(" ")
                    markerRun.text = markerText
                    normalizedRuns[markerIndex] = markerRun
                }
            }
            return normalizedRuns
        }

        var firstContent = afterPeriod
        while firstContent < markerText.endIndex, markerText[firstContent].isWhitespace {
            firstContent = markerText.index(after: firstContent)
        }

        if firstContent < markerText.endIndex, markerText[firstContent].isLetter {
            if afterPeriod == firstContent {
                markerText.insert(" ", at: afterPeriod)
            } else {
                markerText.replaceSubrange(afterPeriod..<firstContent, with: " ")
            }
        } else if let nextRunStart = nextRunStart(after: markerIndex, in: normalizedRuns), nextRunStart.startsWithLetter {
            if nextRunStart.startsWithWhitespace {
                markerText.removeSubrange(afterPeriod..<markerText.endIndex)
                normalizeLeadingWhitespace(in: nextRunStart, runs: &normalizedRuns)
            } else {
                markerText.replaceSubrange(afterPeriod..<markerText.endIndex, with: " ")
            }
        }

        markerRun.text = markerText
        normalizedRuns[markerIndex] = markerRun
        return normalizedRuns
    }

    private struct NextRunStart {
        let runIndex: Int
        let firstContent: String.Index
        let startsWithWhitespace: Bool
        let startsWithLetter: Bool
    }

    private static func nextRunStart(after index: Int, in runs: [ReaderTextRun]) -> NextRunStart? {
        guard index + 1 < runs.count else { return nil }

        for runIndex in (index + 1)..<runs.count {
            let text = runs[runIndex].text
            guard !text.isEmpty else { continue }

            var firstContent = text.startIndex
            while firstContent < text.endIndex, text[firstContent].isWhitespace {
                firstContent = text.index(after: firstContent)
            }

            guard firstContent < text.endIndex else { continue }

            return NextRunStart(
                runIndex: runIndex,
                firstContent: firstContent,
                startsWithWhitespace: firstContent != text.startIndex,
                startsWithLetter: text[firstContent].isLetter
            )
        }

        return nil
    }

    private static func normalizeLeadingWhitespace(in nextRunStart: NextRunStart, runs: inout [ReaderTextRun]) {
        var run = runs[nextRunStart.runIndex]
        var text = run.text
        text.replaceSubrange(text.startIndex..<nextRunStart.firstContent, with: " ")
        run.text = text
        runs[nextRunStart.runIndex] = run
    }

    private static func resolvedURL(_ rawValue: String?, baseURL: URL) -> URL? {
        guard let rawValue = normalized(rawValue) else { return nil }

        if let absolute = URL(string: rawValue), absolute.scheme != nil {
            return absolute
        }

        return URL(string: rawValue, relativeTo: baseURL)?.absoluteURL
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func date(from value: String?) -> Date? {
        guard let value = normalized(value) else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }

        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private static func estimatedReadingMinutes(for text: String) -> Int {
        let words = text
            .split { $0.isWhitespace || $0.isNewline }
            .count

        return max(1, Int(ceil(Double(words) / 225.0)))
    }

    private static func meaningfulTextCount(blocks: [ReaderBlock], fallbackText: String) -> Int {
        if !fallbackText.isEmpty {
            return fallbackText.count
        }

        return blocks.map(blockPlainText).joined(separator: " ").count
    }

    private static func blockPlainText(_ block: ReaderBlock) -> String {
        switch block {
        case .heading(_, let content), .paragraph(let content), .quote(let content), .link(let content, _):
            return content.plainText
        case .unorderedList(let items), .orderedList(let items):
            return items.map { $0.content.plainText }.joined(separator: " ")
        case .code(_, let code):
            return code
        case .image(_, _, let caption):
            return caption ?? ""
        case .divider:
            return ""
        }
    }
}
