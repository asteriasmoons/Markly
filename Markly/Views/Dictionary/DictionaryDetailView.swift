//
//  DictionaryDetailView.swift
//  Markly
//
//  Dictionary Detail Page. Shows the words inside one dictionary as a
//  grid of alternating colored cards. Each card centers the word (in its
//  accent color), its tag chips, up to two lines of the first definition,
//  and the date it was added.
//

import SwiftData
import SwiftUI

struct DictionaryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dictionary: WordDictionary

    @Query(sort: \DictionaryWord.dateAdded, order: .reverse) private var allWords: [DictionaryWord]

    @State private var searchText = ""
    @State private var showingAddWordSheet = false
    @State private var editingWord: DictionaryWord?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var words: [DictionaryWord] {
        allWords.filter { $0.dictionary?.persistentModelID == dictionary.persistentModelID }
    }

    private var filteredWords: [DictionaryWord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return words }

        return words.filter { word in
            word.word.localizedCaseInsensitiveContains(query)
                || word.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || word.definitions.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header
                statsTilesSection
                searchSection

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                        if words.isEmpty {
                            emptyState
                        } else if filteredWords.isEmpty {
                            noSearchMatches
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Array(filteredWords.enumerated()), id: \.element.id) { index, word in
                                    NavigationLink {
                                        DictionaryWordDetailView(word: word) {
                                            editingWord = word
                                        }
                                    } label: {
                                        wordCard(word, cardAccent: accent(for: index))
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Edit") {
                                            editingWord = word
                                        }

                                        Button("Delete", role: .destructive) {
                                            delete(word)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.top, 4)
                    .padding(.bottom, 110)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveSheet(isPresented: $showingAddWordSheet) {
            AddEditDictionaryWordView(word: nil, dictionary: dictionary) {
                showingAddWordSheet = false
            }
        }
        .adaptiveSheet(item: $editingWord) { word in
            AddEditDictionaryWordView(word: word, dictionary: dictionary) {
                editingWord = nil
            }
        }
    }
}

private extension DictionaryDetailView {
    var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(dictionary.name.isEmpty ? "Untitled" : dictionary.name)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(LColors.secondaryAccent)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button {
                    showingAddWordSheet = true
                } label: {
                    CustomAssetIcon(name: "addwavy", size: 30, tint: LColors.secondaryAccent)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add word")

                Button {
                    dismiss()
                } label: {
                    CustomAssetIcon(name: "xmark", size: 30, tint: LColors.secondaryAccent)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var statsTilesSection: some View {
        HStack(spacing: 10) {
            DictionaryStatTile(title: "Words", value: words.count, tint: LColors.primaryActions, icon: "dictionary")
            DictionaryStatTile(title: "Linguistics", value: linguisticCount, tint: LColors.secondaryAccent, icon: "lang")
            DictionaryStatTile(title: "Tags", value: uniqueTagCount, tint: LColors.indicators, icon: "tagsparkle")
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var searchSection: some View {
        HStack(spacing: 10) {
            Image("searchsparkle")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.primaryActions)

            TextField("Search words", text: $searchText)
                .foregroundStyle(LColors.textPrimary)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1)
        )
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var linguisticCount: Int {
        Set(words.map(\.partOfSpeech).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).count
    }

    var uniqueTagCount: Int {
        Set(words.flatMap(\.tags).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }).count
    }

    var emptyState: some View {
        GlassCard(cornerRadius: 22) {
            VStack(spacing: 10) {
                BubblyIconMaterial(tint: LColors.indicators)
                    .mask {
                        Image("bookopen")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)

                Text("No words yet")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.primaryText)

                Text("Add words, definitions, sources, and notes to build this dictionary.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1.2)
        }
    }

    var noSearchMatches: some View {
        GlassCard(cornerRadius: 22) {
            VStack(spacing: 10) {
                Text("No matches")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.primaryText)

                Text("Try a different search.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1.2)
        }
    }

    func wordCard(_ word: DictionaryWord, cardAccent: Color) -> some View {
        GlassCard(cornerRadius: 22, padding: 12) {
            VStack(alignment: .center, spacing: 9) {
                Text(word.word)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(cardAccent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !word.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(Array(word.tags.prefix(2).enumerated()), id: \.offset) { index, tag in
                            DictionaryMiniPill(title: tag, accent: accent(for: index))
                        }

                        if word.tags.count > 2 {
                            DictionaryMiniPill(title: "+\(word.tags.count - 2)", accent: LColors.indicators)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .center)
                    .clipped()
                }

                Text(primaryDefinition(for: word))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)

                Text(word.dateAdded.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(cardAccent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
        }
        .overlay {
            BubblyLightWash(colors: [cardAccent])
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(cardAccent, lineWidth: 1.2)
        }
    }

    func primaryDefinition(for word: DictionaryWord) -> String {
        word.definitions.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "No definition added yet."
    }

    func accent(for index: Int) -> Color {
        switch index % 3 {
        case 1:
            return LColors.secondaryAccent
        case 2:
            return LColors.indicators
        default:
            return LColors.primaryActions
        }
    }

    func delete(_ word: DictionaryWord) {
        modelContext.delete(word)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete dictionary word: \(error)")
        }
    }
}

private struct DictionaryStatTile: View {
    let title: String
    let value: Int
    let tint: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Spacer(minLength: 0)
            }

            Text("\(value)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(LColors.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 20)
        }
        .bubblyTileLift()
    }
}

private struct DictionaryMiniPill: View {
    let title: String
    let accent: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(LColors.primaryText)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                BubblyTileSurface(tint: accent, cornerRadius: 10)
            }
            .bubblyTileLift()
    }
}
