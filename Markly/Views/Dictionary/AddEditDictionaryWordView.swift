//
//  AddEditDictionaryWordView.swift
//  Markly
//
//  Add / Edit form sheet for a single word. Every field title sits OUTSIDE
//  any border — a bold, colored, rounded title directly above its own
//  colored-bordered input. Colors follow the app rotation:
//  blue = primaryActions, pink = secondaryAccent, yellow = indicators.
//

import AVFoundation
import Combine
import SwiftData
import SwiftUI
import UIKit

struct AddEditDictionaryWordView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechReader = DictionarySpeechReader()

    let word: DictionaryWord?
    let dictionary: WordDictionary?
    let onClose: () -> Void

    @State private var wordText = ""
    @State private var partOfSpeech = "Noun"
    @State private var partOfSpeechOpen = false
    @State private var sourceName = ""
    @State private var sourceURL = ""
    @State private var sources: [DictionarySource] = []
    @State private var writtenPronunciation = ""
    @State private var ipaPronunciation = ""
    @State private var synonymInput = ""
    @State private var synonyms: [String] = []
    @State private var antonymInput = ""
    @State private var antonyms: [String] = []
    @State private var definitionInput = ""
    @State private var definitions: [String] = []
    @State private var exampleInput = ""
    @State private var exampleSentences: [String] = []
    @State private var originEtymology = ""
    @State private var relatedWordInput = ""
    @State private var relatedWords: [String] = []
    @State private var usageNoteLabel = ""
    @State private var usageNoteValue = ""
    @State private var usageNotes: [DictionaryUsageNote] = []
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var isFetching = false
    @State private var fetchError: String?

    private let partsOfSpeech = [
        "Noun",
        "Verb",
        "Adjective",
        "Adverb",
        "Pronoun",
        "Preposition"
    ]

    // Color roles
    private let blue = LColors.primaryActions
    private let pink = LColors.secondaryAccent
    private let yellow = LColors.indicators

    private var isEditing: Bool {
        word != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MarklyBackground()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        wordSection
                        partOfSpeechSection
                        sourceSection
                        pronunciationSection
                        synonymsSection
                        antonymsSection
                        definitionsSection
                        examplesSection
                        originSection
                        relatedWordsSection
                        usageNotesSection
                        tagsSection
                        actionsSection
                    }
                    .padding(22)
                    .padding(.bottom, 24)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear(perform: loadExistingWord)
    }
}

// MARK: - Sections

private extension AddEditDictionaryWordView {
    var headerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(isEditing ? "Edit Word" : "New Word")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(pink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Build a personal reference with definitions, examples, sources, and notes.")
                    .font(.subheadline)
                    .foregroundStyle(LColors.textSecondary)
            }

            Button(action: onClose) {
                CustomAssetIcon(name: "xmark", size: 30, tint: pink)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Word — the primary visual focus. Blue bold title above a blue bordered field.
    var wordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldTitle("Word", accent: blue)

            DictionaryWordField(
                placeholder: "Enter the word",
                text: $wordText,
                accent: blue
            )
            .textInputAutocapitalization(.words)

            fetchDetailsButton

            if let fetchError {
                Text(fetchError)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.warning)
            }
        }
    }
    // THE FETCH DETAILS BUTTON BELOW THE WORD TEXT FIELD TO FETCH AND POPULATE ALL FIELDS
    var fetchDetailsButton: some View {
        let canFetch = !wordText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isFetching
        return Button {
            Task { await fetchDetails() }
        } label: {
            HStack(spacing: 7) {
                CustomAssetIcon(name: "sparklesearch", size: 16, tint: LColors.primaryText)
                Text(isFetching ? "Fetching\u{2026}" : "Fetch Details")
                    .font(.system(size: 14, weight: .black, design: .rounded))
            }
            .foregroundStyle(LColors.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background {
                BubblyTileSurface(tint: blue, cornerRadius: LSpacing.buttonRadius)
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .disabled(!canFetch)
        .opacity(canFetch ? 1 : 0.5)
    }

    // Part of Speech — bold section title over a pink Liquid Glass custom dropdown.
    var partOfSpeechSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldTitle("Part of Speech", accent: pink)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    partOfSpeechOpen.toggle()
                }
            } label: {
                HStack {
                    Text(partOfSpeech)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.primaryText)

                    Spacer()

                    CustomAssetIcon(name: partOfSpeechOpen ? "chevup" : "chevdown", size: 14, tint: LColors.primaryText)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background {
                    BubblyTileSurface(tint: pink, cornerRadius: LSpacing.inputRadius)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                        .strokeBorder(pink, lineWidth: 1.2)
                )
                .bubblyTileLift()
            }
            .buttonStyle(.plain)

            if partOfSpeechOpen {
                VStack(spacing: 0) {
                    ForEach(partsOfSpeech, id: \.self) { part in
                        Button {
                            partOfSpeech = part
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                partOfSpeechOpen = false
                            }
                        } label: {
                            HStack {
                                Text(part)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.primaryText)

                                Spacer()

                                if partOfSpeech == part {
                                    CustomAssetIcon(name: "circlemarked", size: 14, tint: LColors.primaryText)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background {
                    BubblyTileSurface(tint: pink, cornerRadius: LSpacing.inputRadius)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                        .strokeBorder(pink, lineWidth: 1.2)
                )
                .bubblyTileLift()
            }
        }
    }

    // Sources — same label/value/add/list interaction pattern used by Usage Notes.
    var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldTitle("Sources", accent: yellow)

            DictionaryWordField(placeholder: "Dictionary, article, book, or reference", text: $sourceName, accent: yellow)

            DictionaryWordField(placeholder: "https://example.com", text: $sourceURL, accent: yellow)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button {
                addSource()
            } label: {
                HStack(spacing: 7) {
                    CustomAssetIcon(name: "addwavy", size: 18, tint: LColors.primaryText)
                    Text("Add Source")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(LColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    BubblyTileSurface(tint: yellow, cornerRadius: LSpacing.buttonRadius)
                }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)

            sourceList
        }
    }

    // Pronunciation — blue title above a blue bordered field with a blue speak button beside it.
    var pronunciationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldTitle("Pronunciation", accent: blue)

            HStack(alignment: .center, spacing: 10) {
                DictionaryWordField(placeholder: "bloo-muh-ree", text: $writtenPronunciation, accent: blue)

                Button {
                    speechReader.speak(wordText)
                } label: {
                    CustomAssetIcon(name: "speaker", size: 20, tint: LColors.primaryText)
                        .frame(width: 52, height: 52)
                        .background {
                            BubblyTileSurface(tint: blue, cornerRadius: 18)
                        }
                        .bubblyTileLift()
                }
                .buttonStyle(.plain)
                .disabled(wordText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Speak word")
            }

            DictionaryWordField(placeholder: "IPA pronunciation (optional)", text: $ipaPronunciation, accent: blue)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    // Synonyms — pink title, pink bordered field, pink chips.
    var synonymsSection: some View {
        ChipEntryField(
            title: "Synonyms",
            accent: pink,
            placeholder: "Type a word, hit return",
            input: $synonymInput,
            items: $synonyms
        )
    }

    // Antonyms — yellow.
    var antonymsSection: some View {
        ChipEntryField(
            title: "Antonyms",
            accent: yellow,
            placeholder: "Type a word, hit return",
            input: $antonymInput,
            items: $antonyms
        )
    }

    // Definitions — blue title, blue bordered field, blue addwavy button beside it, numbered list.
    var definitionsSection: some View {
        NumberedEntryField(
            title: "Definitions",
            accent: blue,
            placeholder: "Add a definition",
            input: $definitionInput,
            items: $definitions
        )
    }

    // Example Sentences — pink.
    var examplesSection: some View {
        NumberedEntryField(
            title: "Example Sentences",
            accent: pink,
            placeholder: "Use the word in a sentence",
            input: $exampleInput,
            items: $exampleSentences
        )
    }

    // Origin / Etymology — yellow title above a yellow bordered medium field.
    var originSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldTitle("Origin / Etymology", accent: yellow)

            DictionaryWordField(
                placeholder: "Where the word came from and how it developed.",
                text: $originEtymology,
                accent: yellow,
                axis: .vertical,
                minHeight: 124
            )
        }
    }

    // Related Words — blue.
    var relatedWordsSection: some View {
        ChipEntryField(
            title: "Related Words",
            accent: blue,
            placeholder: "Type a word, hit return",
            input: $relatedWordInput,
            items: $relatedWords
        )
    }

    // Usage Notes — pink title, two pink bordered fields, a pink add button below.
    var usageNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldTitle("Usage Notes", accent: pink)

            DictionaryWordField(placeholder: "Label (Formal, Slang, Technical…)", text: $usageNoteLabel, accent: pink)

            DictionaryWordField(
                placeholder: "Describe how this word is normally used.",
                text: $usageNoteValue,
                accent: pink,
                axis: .vertical,
                minHeight: 82
            )

            Button {
                addUsageNote()
            } label: {
                HStack(spacing: 7) {
                    CustomAssetIcon(name: "addwavy", size: 18, tint: LColors.primaryText)
                    Text("Add Usage Note")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(LColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    BubblyTileSurface(tint: pink, cornerRadius: LSpacing.buttonRadius)
                }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)

            usageNoteList
        }
    }

    // Tags — yellow.
    var tagsSection: some View {
        ChipEntryField(
            title: "Tags",
            accent: yellow,
            placeholder: "Type a tag, hit return",
            input: $tagInput,
            items: $tags
        )
    }

    var actionsSection: some View {
        HStack {
            DictionaryWordActionButton(title: "Cancel", icon: "xmark", tint: pink) {
                onClose()
            }

            Spacer()

            DictionaryWordActionButton(title: isEditing ? "Save" : "Create", icon: "checkwavy", tint: blue) {
                save()
            }
            .opacity(canSave ? 1 : 0.45)
            .disabled(!canSave)
        }
    }

    var sourceList: some View {
        VStack(spacing: 8) {
            ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(yellow)

                        Text(source.url)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        sources.remove(at: index)
                    } label: {
                        CustomAssetIcon(name: "xmark", size: 18, tint: yellow)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(LColors.raisedSurfaces, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    var usageNoteList: some View {
        VStack(spacing: 8) {
            ForEach(Array(usageNotes.enumerated()), id: \.element.id) { index, note in
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.label)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(pink)

                        Text(note.value)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        usageNotes.remove(at: index)
                    } label: {
                        CustomAssetIcon(name: "xmark", size: 18, tint: pink)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(LColors.raisedSurfaces, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

// MARK: - Helpers

private extension AddEditDictionaryWordView {
    var canSave: Bool {
        !wordText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func fieldTitle(_ title: String, accent: Color) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(accent)
    }
}

// MARK: - Logic

private extension AddEditDictionaryWordView {
    func addSource() {
        let cleanedName = sourceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedURL = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty, !cleanedURL.isEmpty else { return }

        sources.append(DictionarySource(name: cleanedName, url: cleanedURL))
        sourceName = ""
        sourceURL = ""
    }

    func addUsageNote() {
        let cleanedLabel = usageNoteLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedValue = usageNoteValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedLabel.isEmpty, !cleanedValue.isEmpty else { return }

        usageNotes.append(DictionaryUsageNote(label: cleanedLabel, value: cleanedValue))
        usageNoteLabel = ""
        usageNoteValue = ""
    }

    @MainActor
    func fetchDetails() async {
        let trimmed = wordText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isFetching else { return }

        isFetching = true
        fetchError = nil
        defer { isFetching = false }

        do {
            let details = try await DictionaryFetchService.shared.fetchDetails(for: trimmed)
            applyFetched(details)
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't fetch details. Please try again."
        }
    }

    func applyFetched(_ details: FetchedWordDetails) {
        if let pos = details.partOfSpeech, partsOfSpeech.contains(pos) {
            partOfSpeech = pos
        }
        if let value = details.writtenPronunciation, !value.isEmpty {
            writtenPronunciation = value
        }
        if let value = details.ipaPronunciation, !value.isEmpty {
            ipaPronunciation = value
        }
        if let values = details.synonyms, !values.isEmpty {
            synonyms = values
        }
        if let values = details.antonyms, !values.isEmpty {
            antonyms = values
        }
        if let values = details.definitions, !values.isEmpty {
            definitions = values
        }
        if let values = details.exampleSentences, !values.isEmpty {
            exampleSentences = values
        }
        if let value = details.originEtymology, !value.isEmpty {
            originEtymology = value
        }
        if let values = details.relatedWords, !values.isEmpty {
            relatedWords = values
        }
        if let values = details.usageNotes, !values.isEmpty {
            usageNotes = values.map { DictionaryUsageNote(label: $0.label, value: $0.value) }
        }
        if let values = details.tags, !values.isEmpty {
            tags = values
        }
        if let values = details.sources, !values.isEmpty {
            sources = values.map { DictionarySource(name: $0.name, url: $0.url) }
        }
    }

    func loadExistingWord() {
        guard let word else { return }

        wordText = word.word
        partOfSpeech = word.partOfSpeech
        sources = word.sources
        writtenPronunciation = word.writtenPronunciation
        ipaPronunciation = word.ipaPronunciation
        synonyms = word.synonyms
        antonyms = word.antonyms
        definitions = word.definitions
        exampleSentences = word.exampleSentences
        originEtymology = word.originEtymology
        relatedWords = word.relatedWords
        usageNotes = word.usageNotes
        tags = word.tags
    }

    func save() {
        let cleanedWord = wordText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedWord.isEmpty else { return }

        if let word {
            word.word = cleanedWord
            word.partOfSpeech = partOfSpeech
            word.sources = sources
            word.writtenPronunciation = writtenPronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
            word.ipaPronunciation = ipaPronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
            word.synonyms = synonyms
            word.antonyms = antonyms
            word.definitions = definitions
            word.exampleSentences = exampleSentences
            word.originEtymology = originEtymology.trimmingCharacters(in: .whitespacesAndNewlines)
            word.relatedWords = relatedWords
            word.usageNotes = usageNotes
            word.tags = tags
            word.dateModified = Date()
        } else {
            let newWord = DictionaryWord(
                word: cleanedWord,
                partOfSpeech: partOfSpeech,
                sourceNames: sources.map(\.name),
                sourceURLs: sources.map(\.url),
                writtenPronunciation: writtenPronunciation.trimmingCharacters(in: .whitespacesAndNewlines),
                ipaPronunciation: ipaPronunciation.trimmingCharacters(in: .whitespacesAndNewlines),
                synonyms: synonyms,
                antonyms: antonyms,
                definitions: definitions,
                exampleSentences: exampleSentences,
                originEtymology: originEtymology.trimmingCharacters(in: .whitespacesAndNewlines),
                relatedWords: relatedWords,
                usageNotes: usageNotes,
                tags: tags,
                dictionary: dictionary
            )
            modelContext.insert(newWord)
        }

        do {
            try modelContext.save()
            onClose()
        } catch {
            print("Failed to save dictionary word: \(error)")
        }
    }
}

// MARK: - Chip entry (type + return -> pill chips)

private struct ChipEntryField: View {
    let title: String
    let accent: Color
    let placeholder: String
    @Binding var input: String
    @Binding var items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            DictionaryWordField(placeholder: placeholder, text: $input, accent: accent)
                .submitLabel(.done)
                .onSubmit(add)

            if !items.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Button {
                            items.removeAll { $0 == item }
                        } label: {
                            DictionaryWordChip(title: item, accent: accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func add() {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        if !items.contains(where: { $0.caseInsensitiveCompare(cleaned) == .orderedSame }) {
            items.append(cleaned)
        }
        input = ""
    }
}

// MARK: - Numbered entry (field + add button -> numbered list)

private struct NumberedEntryField: View {
    let title: String
    let accent: Color
    let placeholder: String
    @Binding var input: String
    @Binding var items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            HStack(alignment: .center, spacing: 10) {
                DictionaryWordField(placeholder: placeholder, text: $input, accent: accent)

                Button(action: add) {
                    CustomAssetIcon(name: "addwavy", size: 20, tint: LColors.primaryText)
                        .frame(width: 52, height: 52)
                        .background {
                            BubblyTileSurface(tint: accent, cornerRadius: 18)
                        }
                        .bubblyTileLift()
                }
                .buttonStyle(.plain)
            }

            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.primaryText)
                                    .frame(width: 28, height: 28)
                                    .background {
                                        BubblyTileSurface(tint: accent, cornerRadius: 14)
                                    }
                                    .bubblyTileLift()

                                Spacer()

                                Button {
                                    items.remove(at: index)
                                } label: {
                                    BubblyIconMaterial(tint: accent)
                                        .mask {
                                            Image("xmark")
                                                .resizable()
                                                .scaledToFit()
                                        }
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(accent.opacity(0.16))

                            Text(item)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(LColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        .background(LColors.raisedSurfaces)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }

    private func add() {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        items.append(cleaned)
        input = ""
    }
}

// MARK: - Supporting Views

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var usedWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let proposedRowWidth = rowWidth + (rowWidth > 0 ? spacing : 0) + size.width

            if rowWidth > 0 && proposedRowWidth > maxWidth {
                usedWidth = max(usedWidth, rowWidth)
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = proposedRowWidth
                rowHeight = max(rowHeight, size.height)
            }
        }

        usedWidth = max(usedWidth, rowWidth)
        totalHeight += rowHeight
        return CGSize(width: min(usedWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct DictionaryWordField: View {
    let placeholder: String
    @Binding var text: String
    let accent: Color
    var axis: Axis = .horizontal
    var minHeight: CGFloat = 52
    var fontSize: CGFloat = 15

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .font(.system(size: fontSize, weight: .regular, design: .rounded))
            .foregroundStyle(LColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, axis == .vertical ? 12 : 0)
            .frame(minHeight: minHeight, alignment: axis == .vertical ? .topLeading : .leading)
            .background(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .fill(LColors.raisedSurfaces)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .strokeBorder(accent, lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous))
    }
}

private struct DictionaryWordChip: View {
    let title: String
    let accent: Color

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(LColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                BubblyTileSurface(tint: accent, cornerRadius: 16)
            }
            .bubblyTileLift()
    }
}

private struct DictionaryWordActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                CustomAssetIcon(name: icon, size: 14, tint: LColors.primaryText)

                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(LColors.primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                BubblyTileSurface(tint: tint, cornerRadius: LSpacing.buttonRadius)
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Keyboard

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Speech

final class DictionarySpeechReader: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // A deliberate tap on the speaker should be heard even if the ringer
        // is on silent, and should quiet any other audio while it plays.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session for speech: \(error)")
        }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}
