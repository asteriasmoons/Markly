//
//  DictionaryView.swift
//  Markly
//
//  Top-level Dictionary tab. Lists the user's dictionaries as a grid of
//  cards (mirrors the Submitted Reports grid) with a search box. Tapping
//  a dictionary opens its detail page (the word grid).
//

import SwiftData
import SwiftUI

struct DictionaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordDictionary.createdAt, order: .reverse) private var dictionaries: [WordDictionary]
    @Query(sort: \DictionaryWord.dateAdded, order: .reverse) private var allWords: [DictionaryWord]

    @State private var searchText = ""
    @State private var showingAddDictionarySheet = false
    @State private var editingDictionary: WordDictionary?
    @State private var dictionaryToDelete: WordDictionary?
    @State private var showingDeleteDialog = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredDictionaries: [WordDictionary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return dictionaries }

        return dictionaries.filter { dictionary in
            dictionary.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                    header
                    statsTilesSection
                    searchBox

                    if filteredDictionaries.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(filteredDictionaries.enumerated()), id: \.element.id) { index, dictionary in
                                NavigationLink {
                                    DictionaryDetailView(dictionary: dictionary)
                                } label: {
                                    dictionaryCard(dictionary, accent: accent(for: index))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Edit") {
                                        editingDictionary = dictionary
                                    }

                                    Button("Delete", role: .destructive) {
                                        dictionaryToDelete = dictionary
                                        showingDeleteDialog = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 110)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Delete Dictionary",
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Dictionary", role: .destructive) {
                if let dictionaryToDelete {
                    delete(dictionaryToDelete)
                }
            }

            Button("Cancel", role: .cancel) {
                dictionaryToDelete = nil
            }
        } message: {
            Text("This deletes the dictionary and every word saved inside it.")
        }
        .adaptiveSheet(isPresented: $showingAddDictionarySheet) {
            AddEditDictionaryView(dictionary: nil) {
                showingAddDictionarySheet = false
            }
        }
        .adaptiveSheet(item: $editingDictionary) { dictionary in
            AddEditDictionaryView(dictionary: dictionary) {
                editingDictionary = nil
            }
        }
    }
}

private extension DictionaryView {
    var header: some View {
        HStack(alignment: .center) {
            Text("Dictionary")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(LColors.secondaryAccent)

            Spacer()

            Button {
                showingAddDictionarySheet = true
            } label: {
                CustomAssetIcon(name: "addwavy", size: 30, tint: LColors.secondaryAccent)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add dictionary")
        }
    }

    var statsTilesSection: some View {
        HStack(spacing: 10) {
            DictionaryOverviewStatTile(title: "Dictionaries", value: dictionaries.count, tint: LColors.primaryActions, icon: "dictionary")
            DictionaryOverviewStatTile(title: "Words", value: allWords.count, tint: LColors.secondaryAccent, icon: "writepen")
            DictionaryOverviewStatTile(title: "Tags", value: uniqueTagCount, tint: LColors.indicators, icon: "tagsparkle")
        }
    }

    var uniqueTagCount: Int {
        Set(allWords.flatMap(\.tags).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }).count
    }

    var searchBox: some View {
        HStack(spacing: 10) {
            Image("searchsparkle")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.primaryActions)

            TextField("Search dictionaries", text: $searchText)
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
    }

    var emptyState: some View {
        GlassCard(cornerRadius: 22) {
            VStack(spacing: 10) {
                BubblyIconMaterial(tint: LColors.indicators)
                    .mask {
                        Image("books")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)

                Text(dictionaries.isEmpty ? "No dictionaries yet" : "No matches")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.primaryText)

                Text(dictionaries.isEmpty
                     ? "Create a dictionary to start collecting words, definitions, sources, and notes."
                     : "Try a different search.")
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
                .strokeBorder(LColors.secondaryAccent, lineWidth: 1.2)
        }
    }

    func dictionaryCard(_ dictionary: WordDictionary, accent: Color) -> some View {
        GlassCard(cornerRadius: 22, padding: 12) {
            VStack(alignment: .center, spacing: 10) {
                liquidGlassIcon(dictionary.iconName.isEmpty ? "openbook" : dictionary.iconName, accent: accent)

                Text(dictionary.name.isEmpty ? "Untitled" : dictionary.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .center, spacing: 3) {
                    Text(wordCountLabel(for: dictionary))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Text(dictionary.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                CustomAssetIcon(name: "chevright", size: 15, tint: accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 158)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        }
    }

    func liquidGlassIcon(_ name: String, accent: Color) -> some View {
        ZStack {
            BubblyTileSurface(tint: accent, cornerRadius: 18)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(accent, lineWidth: 1.2)
                }

            MarklyIconView(iconId: name, size: 20)
                .foregroundStyle(LColors.primaryText)
        }
        .frame(width: 46, height: 46)
        .bubblyTileLift()
    }

    func wordCountLabel(for dictionary: WordDictionary) -> String {
        let count = dictionary.wordCount
        return count == 1 ? "1 word" : "\(count) words"
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

    func delete(_ dictionary: WordDictionary) {
        modelContext.delete(dictionary)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete dictionary: \(error)")
        }

        dictionaryToDelete = nil
    }
}

private struct DictionaryOverviewStatTile: View {
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

// MARK: - Shared Flow Layout
// Kept here (top-level) because AddEditDictionaryWordView, DictionaryDetailView,
// and DictionaryWordDetailView all rely on it for wrapping chips.

struct DictionaryFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

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
                totalHeight += rowHeight + lineSpacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = proposedRowWidth
                rowHeight = max(rowHeight, size.height)
            }
        }

        usedWidth = max(usedWidth, rowWidth)
        totalHeight += rowHeight
        let resolvedWidth = maxWidth.isFinite ? maxWidth : usedWidth
        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > bounds.minX, currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + lineSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
