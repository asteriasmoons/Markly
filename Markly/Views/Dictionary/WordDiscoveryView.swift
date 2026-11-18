//
//  WordDiscoveryView.swift
//  Markly
//
//  Discover random words and save them to existing dictionaries.
//

import SwiftData
import SwiftUI

struct WordDiscoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordDictionary.createdAt, order: .reverse) private var dictionaries: [WordDictionary]
    @Query private var savedWords: [DictionaryWord]

    @State private var selectedCategory: DiscoveryCategory?
    @State private var selectedDifficulty: DiscoveryDifficulty?
    @State private var discoveredWord: FetchedWordDetails?
    @State private var recentWords: [String] = []
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingDictionaryPicker = false
    @State private var saveMessage: String?

    private let blue = LColors.primaryActions
    private let pink = LColors.secondaryAccent
    private let yellow = LColors.indicators

    private var wordText: String {
        discoveredWord?.word?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    Text("Meet a new word, explore its meaning, and keep the ones you love.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    VStack(alignment: .leading, spacing: 9) {
                        CustomDropdown(
                            title: "Choose a Category",
                            options: DiscoveryCategory.allCases,
                            labelFor: { $0.title },
                            accent: blue,
                            maxVisibleRows: 4,
                            showsDividers: true,
                            emphasizedStyle: true,
                            selection: $selectedCategory
                        )

                        if let selectedCategory {
                            Text(selectedCategory.subtitle)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .disabled(isLoading || isSaving)
                    .onChange(of: selectedCategory) { _, _ in
                        discoveredWord = nil
                        errorMessage = nil
                        saveMessage = nil
                    }

                    DiscoveryDifficultyPicker(selection: $selectedDifficulty)
                        .disabled(isLoading || isSaving)
                        .onChange(of: selectedDifficulty) { _, _ in
                            discoveredWord = nil
                            errorMessage = nil
                            saveMessage = nil
                        }

                    if isLoading && discoveredWord == nil {
                        ProgressView("Discovering a word…")
                            .tint(blue)
                            .frame(maxWidth: .infinity, minHeight: 190)
                    } else if let details = discoveredWord {
                        wordContent(details)
                    } else {
                        GlassCard(cornerRadius: 22) {
                            VStack(spacing: 12) {
                                CustomAssetIcon(name: "dictionary", size: 38, tint: yellow)
                                Text("A new word awaits")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.primaryText)
                                Text("Choose a category and difficulty, then discover a word.")
                                    .font(.subheadline)
                                    .foregroundStyle(LColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.warning)
                    }

                    if let saveMessage {
                        Text(saveMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(yellow)
                    }

                    Button {
                        Task { await discoverWord() }
                    } label: {
                        actionLabel(isLoading ? "Discovering…" : "Discover Word", icon: "sparklesearch", tint: yellow)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading || isSaving || selectedCategory == nil || selectedDifficulty == nil)
                    .opacity(isLoading || selectedCategory == nil || selectedDifficulty == nil ? 0.6 : 1)

                    if discoveredWord != nil {
                        Button {
                            showingDictionaryPicker = true
                        } label: {
                            actionLabel(isSaving ? "Saving & Enriching…" : "Save to Dictionary", icon: "addwavy", tint: blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading || isSaving || wordText.isEmpty)
                    }
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 110)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Save to Dictionary",
            isPresented: $showingDictionaryPicker,
            titleVisibility: .visible
        ) {
            ForEach(dictionaries, id: \.persistentModelID) { dictionary in
                Button(dictionary.name.isEmpty ? "Untitled" : dictionary.name) {
                    Task { await saveWord(to: dictionary) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(dictionaries.isEmpty
                 ? "Create a dictionary first to save discovered words."
                 : "Choose a dictionary for \(wordText).")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Word Discovery")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(pink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button { dismiss() } label: {
                CustomAssetIcon(name: "xmark", size: 30, tint: pink)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Word Discovery")
        }
    }

    @ViewBuilder
    private func wordContent(_ details: FetchedWordDetails) -> some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 16) {
                Text(wordText.capitalized)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(blue)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let part = details.partOfSpeech, !part.isEmpty {
                    Text(part.capitalized)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(pink)
                }

                if let pronunciation = [details.writtenPronunciation, details.ipaPronunciation]
                    .compactMap({ $0 })
                    .first(where: { !$0.isEmpty }) {
                    Text(pronunciation)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                if let definitions = details.definitions, !definitions.isEmpty {
                    infoSection("Definitions", items: definitions, tint: yellow)
                }

                if let examples = details.exampleSentences, !examples.isEmpty {
                    infoSection("Examples", items: examples, tint: blue)
                }

                if let synonyms = details.synonyms, !synonyms.isEmpty {
                    infoSection("Synonyms", items: [synonyms.prefix(12).joined(separator: ", ")], tint: pink)
                }

                if let origin = details.originEtymology, !origin.isEmpty {
                    infoSection("Origin & Etymology", items: [origin], tint: yellow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func infoSection(_ title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(tint)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func actionLabel(_ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            CustomAssetIcon(name: icon, size: 20, tint: LColors.primaryText)
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
        }
        .foregroundStyle(LColors.primaryText)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: LSpacing.buttonRadius)
        }
        .bubblyTileLift()
    }

    @MainActor
    private func discoverWord() async {
        guard !isLoading,
              let category = selectedCategory,
              let difficulty = selectedDifficulty else { return }
        isLoading = true
        errorMessage = nil
        saveMessage = nil
        defer { isLoading = false }

        do {
            let result = try await DictionaryFetchService.shared.fetchRandomWord(
                category: category,
                difficulty: difficulty,
                excluding: recentWords
            )
            guard let word = result.word, !word.isEmpty else {
                throw DictionaryFetchError.notFound
            }
            discoveredWord = result
            recentWords.append(word)
            if recentWords.count > 30 {
                recentWords.removeFirst(recentWords.count - 30)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't discover a word. Please try again."
        }
    }

    @MainActor
    private func saveWord(to dictionary: WordDictionary) async {
        guard !isSaving, !isLoading, !wordText.isEmpty else { return }
        let selectedWord = wordText
        saveMessage = nil

        let alreadySaved = savedWords.contains {
            $0.dictionary?.persistentModelID == dictionary.persistentModelID
                && $0.word.compare(wordText, options: .caseInsensitive) == .orderedSame
        }
        if alreadySaved {
            saveMessage = "This word is already in \(dictionary.name)."
            return
        }

        isSaving = true
        defer { isSaving = false }

        // Run the same enrichment request as the Add/Edit Word sheet before saving.
        let details: FetchedWordDetails
        do {
            details = try await DictionaryFetchService.shared.fetchDetails(for: selectedWord)
        } catch {
            saveMessage = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't fetch the word's details. Please try again."
            return
        }

        let sources = details.sources ?? []
        let entry = DictionaryWord(
            word: selectedWord,
            partOfSpeech: details.partOfSpeech ?? "Noun",
            sourceNames: sources.map(\.name),
            sourceURLs: sources.map(\.url),
            writtenPronunciation: details.writtenPronunciation ?? "",
            ipaPronunciation: details.ipaPronunciation ?? "",
            synonyms: details.synonyms ?? [],
            antonyms: details.antonyms ?? [],
            definitions: details.definitions ?? [],
            exampleSentences: details.exampleSentences ?? [],
            originEtymology: details.originEtymology ?? "",
            relatedWords: details.relatedWords ?? [],
            usageNotes: (details.usageNotes ?? []).map {
                DictionaryUsageNote(label: $0.label, value: $0.value)
            },
            tags: details.tags ?? [],
            dictionary: dictionary
        )

        modelContext.insert(entry)
        do {
            try modelContext.save()
            saveMessage = "Saved \(wordText) to \(dictionary.name)."
        } catch {
            modelContext.delete(entry)
            saveMessage = "Couldn't save this word. Please try again."
        }
    }
}
