//
//  DictionaryFetchService.swift
//  Markly
//
//  Calls the Voxiverse backend (/api/dictionary/fetch) which aggregates free
//  dictionary/reference sources and Groq enrichment, and returns a single
//  normalized result that maps onto the existing DictionaryWord form fields.
//  Mirrors the networking pattern used by UserProfileService.
//

import Foundation

final class DictionaryFetchService {
    static let shared = DictionaryFetchService()
    private init() {}

    private let baseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              !url.isEmpty else {
            return "https://appapi.voxiverse.ink"
        }
        return url
    }()

    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func fetchDetails(for word: String) async throws -> FetchedWordDetails {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DictionaryFetchError.emptyWord }

        var request = URLRequest(url: URL(string: "\(baseURL)/api/dictionary/fetch")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["word": trimmed])
        request.timeoutInterval = 60

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw DictionaryFetchError.invalidResponse
        }

        if http.statusCode == 404 {
            throw DictionaryFetchError.notFound
        }

        guard (200..<300).contains(http.statusCode) else {
            throw DictionaryFetchError.serverError
        }

        return try decoder.decode(FetchedWordDetails.self, from: data)
    }
}

enum DictionaryFetchError: LocalizedError {
    case emptyWord
    case invalidResponse
    case notFound
    case serverError

    var errorDescription: String? {
        switch self {
        case .emptyWord:
            return "Enter a word first."
        case .invalidResponse:
            return "Couldn't reach the dictionary service."
        case .notFound:
            return "No dictionary details found for that word."
        case .serverError:
            return "The dictionary service is unavailable right now."
        }
    }
}

// MARK: - Normalized response

struct FetchedWordDetails: Decodable {
    let word: String?
    let partOfSpeech: String?
    let sources: [FetchedSource]?
    let writtenPronunciation: String?
    let ipaPronunciation: String?
    let synonyms: [String]?
    let antonyms: [String]?
    let definitions: [String]?
    let exampleSentences: [String]?
    let originEtymology: String?
    let relatedWords: [String]?
    let usageNotes: [FetchedUsageNote]?
    let tags: [String]?
}

struct FetchedSource: Decodable {
    let name: String
    let url: String
}

struct FetchedUsageNote: Decodable {
    let label: String
    let value: String
}
