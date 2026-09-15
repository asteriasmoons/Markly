//
//  BookmarkFolderDetailView.swift
//  Markly
//

import SwiftUI
import SwiftData

struct BookmarkFolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let folder: BookmarkFolder

    @Query(sort: \BookmarkItem.createdAt, order: .reverse)
    private var bookmarks: [BookmarkItem]

    @Query(sort: \BookmarkFolder.createdAt, order: .forward)
    private var folders: [BookmarkFolder]

    @State private var searchText: String = ""
    @State private var selectedFilter: BookmarkQuickFilter = .all
    @State private var selectedSort: BookmarkSortOption = .newest

    @State private var selectedBookmark: BookmarkItem? = nil
    @State private var showAddBookmarkPopup: Bool = false

    @State private var bookmarkToDelete: BookmarkItem? = nil
    @State private var showDeleteDialog: Bool = false

    private let recentDays: Int = 7

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                headerSection

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        folderStatsTilesSection
                        controlSection
                        bookmarksSection
                    }
                    .padding(.bottom, 120)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            importPendingSharedBookmark()
        }
        .navigationDestination(item: $selectedBookmark) { bookmark in
            BookmarkDetailView(
                bookmark: bookmark,
                availableFolders: sortedFoldersForMoves
            )
        }
        .adaptiveSheet(isPresented: $showAddBookmarkPopup) {
            AddEditBookmarkView(
                bookmark: nil,
                folders: sortedFoldersForMoves,
                initialFolder: folder,
                onClose: {
                    showAddBookmarkPopup = false
                }
            )
        }
        .alert("Delete Bookmark", isPresented: $showDeleteDialog) {
            Button("Delete", role: .destructive) {
                if let bookmarkToDelete {
                    deleteBookmark(bookmarkToDelete)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this bookmark? This cannot be undone.")
        }
    }
}

// MARK: - Sections

private extension BookmarkFolderDetailView {
    var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Folder icon ZStack removed as requested

                Text(folder.name.isEmpty ? "Untitled Folder" : folder.name)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Button {
                        showAddBookmarkPopup = true
                    } label: {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(LColors.secondaryAccent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                    } label: {
                        Image("xmark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(LColors.secondaryAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 0)
            .padding(.horizontal, LSpacing.pageHorizontal)
        }
    }

    var folderStatsTilesSection: some View {
        HStack(spacing: 10) {
            FolderDetailStatTile(
                title: "Bookmarks",
                value: folderBookmarks.count,
                tint: LColors.primaryActions,
                icon: "starmark"
            )

            FolderDetailStatTile(
                title: "Favorites",
                value: folderFavoriteCount,
                tint: LColors.secondaryAccent,
                icon: "starfill"
            )

            FolderDetailStatTile(
                title: "Notes",
                value: folderNoteCount,
                tint: LColors.indicators,
                icon: "starnote"
            )
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var controlSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image("searchsparkle")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(LColors.primaryActions)

                    TextField("Search title, description, tags, notes, or link", text: $searchText)
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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(BookmarkQuickFilter.allCases) { filter in
                            filterChip(
                                title: filter.label,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                }

                Menu {
                    ForEach(BookmarkSortOption.allCases) { option in
                        Button(option.label) {
                            selectedSort = option
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSort.label)
                            .foregroundStyle(LColors.primaryText)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Image("arrows")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(LColors.primaryText)
                    }
                    .shadow(color: LColors.background.opacity(0.72), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background {
                        BubblyTileSurface(tint: LColors.indicators, cornerRadius: LSpacing.inputRadius)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: LSpacing.inputRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: LSpacing.inputRadius)
                            .stroke(LColors.indicators, lineWidth: 1.2)
                    )
                    .bubblyTileLift()
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1.2)
        )
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if filteredAndSortedBookmarks.isEmpty {
                emptyStateCard
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(Array(filteredAndSortedBookmarks.enumerated()), id: \.element.id) { index, bookmark in
                        BookmarkCard(
                            bookmark: bookmark,
                            folderName: folder.name.isEmpty ? "Untitled Folder" : folder.name,
                            onToggleFavorite: {
                                toggleFavorite(for: bookmark)
                            },
                            onOpen: {
                                selectedBookmark = bookmark
                            },
                            onMoveToFolder: { targetFolder in
                                move(bookmark: bookmark, to: targetFolder)
                            },
                            onDelete: {
                                bookmarkToDelete = bookmark
                                showDeleteDialog = true
                            },
                            availableFolders: sortedFoldersForMoves
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(bookmarkCardBorderAccent(at: index), lineWidth: 1.2)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var emptyStateCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image("starmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white.opacity(0.85))

                Text(emptyStateTitle)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if selectedFilter != .all || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LButton(title: "Show All", icon: "inboxfill", style: .secondary) {
                        selectedFilter = .all
                        searchText = ""
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(LColors.secondaryAccent, lineWidth: 1.2)
        )
    }

}

// MARK: - Computed Data

private extension BookmarkFolderDetailView {
    var sortedFoldersForMoves: [BookmarkFolder] {
        folders.sorted {
            if $0.systemKey == "inbox" && $1.systemKey != "inbox" { return true }
            if $1.systemKey == "inbox" && $0.systemKey != "inbox" { return false }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var folderBookmarks: [BookmarkItem] {
        bookmarks.filter { bookmark in
            bookmark.folder?.persistentModelID == folder.persistentModelID
        }
    }

    var folderFavoriteCount: Int {
        folderBookmarks.filter(\.isFavorite).count
    }

    var folderNoteCount: Int {
        folderBookmarks.reduce(0) { count, bookmark in
            let savedNoteCount = bookmark.savedNotes?.count ?? 0
            if savedNoteCount > 0 {
                return count + savedNoteCount
            }

            let legacyNote = bookmark.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            return legacyNote.isEmpty ? count : count + 1
        }
    }

    func bookmarkCardBorderAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    var filteredAndSortedBookmarks: [BookmarkItem] {
        let now = Date()
        let recentCutoff = Calendar.current.date(byAdding: .day, value: -recentDays, to: now) ?? now

        let base = folderBookmarks.filter { bookmark in
            let matchesQuickFilter: Bool = {
                switch selectedFilter {
                case .all:
                    return true
                case .favorites:
                    return bookmark.isFavorite
                case .recent:
                    return bookmark.createdAt >= recentCutoff
                }
            }()

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch: Bool = {
                guard !query.isEmpty else { return true }
                let haystack = [
                    bookmark.title,
                    bookmark.bookmarkDescription,
                    bookmark.tagsRaw,
                    bookmark.notes,
                    bookmark.link
                ]
                .joined(separator: " ")
                .lowercased()

                return haystack.contains(query.lowercased())
            }()

            return matchesQuickFilter && matchesSearch
        }

        switch selectedSort {
        case .newest:
            return base.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return base.sorted { $0.createdAt < $1.createdAt }
        case .titleAZ:
            return base.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }

    var emptyStateTitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No bookmarks matched your search"
        }

        switch selectedFilter {
        case .favorites:
            return "No favorites in this folder"
        case .recent:
            return "No recent bookmarks in this folder"
        case .all:
            return "This folder is empty"
        }
    }

    var emptyStateMessage: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Try a different keyword, clear the search, or switch your filter."
        }

        switch selectedFilter {
        case .favorites:
            return "Tap the star on any bookmark card in this folder to build a favorites pile here."
        case .recent:
            return "Anything added to this folder within the last \(recentDays) days will show up here."
        case .all:
            return "Save a bookmark and it will appear in this folder immediately."
        }
    }
}

// MARK: - Actions

private extension BookmarkFolderDetailView {
    func importPendingSharedBookmark() {
        SharedBookmarkImportManager.importPendingBookmark(modelContext: modelContext)
    }

    func toggleFavorite(for bookmark: BookmarkItem) {
        bookmark.isFavorite.toggle()
        bookmark.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }

    func move(bookmark: BookmarkItem, to targetFolder: BookmarkFolder) {
        bookmark.folder = targetFolder
        bookmark.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to move bookmark: \(error)")
        }
    }

    func deleteBookmark(_ bookmark: BookmarkItem) {
        bookmark.savedNotes?.forEach { note in
            modelContext.delete(note)
        }
        modelContext.delete(bookmark)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete bookmark: \(error)")
        }

        bookmarkToDelete = nil
    }

}

// MARK: - Small UI Pieces

private extension BookmarkFolderDetailView {
    func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LColors.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: 999)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? LColors.primaryText.opacity(0.48) : LColors.secondaryAccent,
                            lineWidth: isSelected ? 1.4 : 1
                        )
                }
                .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }
}

private struct FolderDetailStatTile: View {
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

// MARK: - Folder Filter + Sort Enums

enum BookmarkQuickFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case recent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "All"
        case .favorites:
            return "Favorites"
        case .recent:
            return "Recent"
        }
    }
}

enum BookmarkSortOption: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case titleAZ

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest:
            return "Newest First"
        case .oldest:
            return "Oldest First"
        case .titleAZ:
            return "Title A–Z"
        }
    }
}
