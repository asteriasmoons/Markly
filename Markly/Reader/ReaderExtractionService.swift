//
//  ReaderExtractionService.swift
//  Markly
//

import Foundation

enum ReaderExtractionError: LocalizedError {
    case invalidURL
    case readabilityUnavailable
    case unsupported
    case extractionFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The saved link is not a valid webpage."
        case .readabilityUnavailable:
            return "Reader support is unavailable in this build."
        case .unsupported:
            return "Reader view is not available for this page."
        case .extractionFailed:
            return "Reader extraction failed."
        }
    }
}

@MainActor
final class ReaderExtractionService {
    static let shared = ReaderExtractionService()

    private var cache: [URL: ReaderArticle] = [:]
    private var activeExtractor: ReadabilityWebView?

    private init() {}

    func article(for sourceURL: URL) async throws -> ReaderArticle {
        let canonicalURL = sourceURL.absoluteURL

        if let cached = cache[canonicalURL] {
            return cached
        }

        let extractor = ReadabilityWebView()
        activeExtractor = extractor

        do {
            let payload = try await extractor.extract(from: canonicalURL)
            try Task.checkCancellation()
            let article = try ReaderHTMLParser.makeArticle(from: payload, sourceURL: canonicalURL)
            cache[canonicalURL] = article
            activeExtractor = nil
            return article
        } catch is CancellationError {
            extractor.cancel()
            activeExtractor = nil
            throw CancellationError()
        } catch ReaderParseError.unsupported {
            activeExtractor = nil
            throw ReaderExtractionError.unsupported
        } catch let error as ReaderExtractionError {
            activeExtractor = nil
            throw error
        } catch {
            activeExtractor = nil
            print("Reader extraction failed for \(canonicalURL.absoluteString): \(error)")
            throw ReaderExtractionError.extractionFailed
        }
    }

    func cancelActiveExtraction() {
        activeExtractor?.cancel()
        activeExtractor = nil
    }
}

