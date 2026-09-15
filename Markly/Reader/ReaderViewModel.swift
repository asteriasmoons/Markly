//
//  ReaderViewModel.swift
//  Markly
//

import Foundation
import Combine

@MainActor
final class ReaderViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(ReaderArticle)
        case failed
    }

    @Published private(set) var state: State = .idle

    private let sourceURL: URL
    private var loadTask: Task<Void, Never>?

    init(sourceURL: URL) {
        self.sourceURL = sourceURL
    }

    func load() {
        guard case .idle = state else { return }

        state = .loading
        loadTask = Task {
            do {
                let article = try await ReaderExtractionService.shared.article(for: sourceURL)
                guard !Task.isCancelled else { return }
                state = .loaded(article)
            } catch is CancellationError {
                state = .idle
            } catch {
                state = .failed
            }
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        ReaderExtractionService.shared.cancelActiveExtraction()
    }
}
