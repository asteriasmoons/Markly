//
//  BookmarksView.swift
//  Markly
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BookmarksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @Query(sort: \BookmarkFolder.createdAt, order: .forward)
    private var folders: [BookmarkFolder]

    @Query(sort: \BookmarkItem.createdAt, order: .reverse)
    private var bookmarks: [BookmarkItem]

    @State private var searchText: String = ""

    @State private var showingAddBookmarkScreen = false
    @State private var showingAddFolderScreen = false
    @State private var editingFolder: BookmarkFolder? = nil
    @State private var visibleFolderCount: Int = 5
    @State private var isReorderMode: Bool = false
    @State private var draggedFolderID: PersistentIdentifier? = nil
    @State private var pendingReorderFolder: BookmarkFolder? = nil
    @State private var folderToDelete: BookmarkFolder? = nil
    @State private var showingDeleteFolderDialog: Bool = false
    @State private var showingSignInSheet: Bool = false
    @State private var hasInitializedView = false

    private let recentDays: Int = 7

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection
                    statsTilesSection
                    searchSection
                    folderSection
                }
                .padding(.bottom, 188)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            repairDuplicateInboxesIfNeeded()
            importPendingSharedBookmark()
        }
        .onAppear {
            if !hasInitializedView {
                visibleFolderCount = 5
                hasInitializedView = true
            }
            resetReorderStateIfNeeded()
            importPendingSharedBookmark()
            if appState.isSignedIn {
                showingSignInSheet = false
            } else {
                showingSignInSheet = true
            }
        }
        .onChange(of: appState.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                showingSignInSheet = false
            }
        }
        .confirmationDialog(
            "Delete Folder",
            isPresented: $showingDeleteFolderDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                if let folderToDelete {
                    deleteFolder(folderToDelete)
                }
            }

            Button("Cancel", role: .cancel) {
                folderToDelete = nil
            }
        } message: {
            Text("This will delete the folder and move its bookmarks into Inbox.")
        }
        .adaptiveSheet(isPresented: $showingAddBookmarkScreen) {
            AddEditBookmarkView(
                bookmark: nil,
                folders: sortedFoldersForStrip,
                onClose: {
                    showingAddBookmarkScreen = false
                }
            )
        }
        .adaptiveSheet(isPresented: $showingAddFolderScreen) {
            AddEditBookmarkFolderView(
                folder: nil,
                onClose: {
                    showingAddFolderScreen = false
                }
            )
        }
        .adaptiveSheet(item: $editingFolder) { folder in
            AddEditBookmarkFolderView(
                folder: folder,
                onClose: {
                    editingFolder = nil
                }
            )
        }
        .adaptiveSheet(isPresented: $showingSignInSheet) {
            SignInView()
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Sections

private extension BookmarksView {
    var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Bookmarks")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)
                Spacer()

                if isReorderMode {
                    LButton(title: "Done", icon: "checkwavy", style: .secondary) {
                        withAnimation {
                            isReorderMode = false
                            draggedFolderID = nil
                            pendingReorderFolder = nil
                        }
                    }
                }

                Button {
                    showingAddFolderScreen = true
                } label: {
                    Image("addwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(LColors.secondaryAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            .padding(.horizontal, LSpacing.pageHorizontal)
        }
    }

    var statsTilesSection: some View {
        HStack(spacing: 10) {
            BookmarkStatTile(
                title: "Folders",
                value: folders.count,
                tint: LColors.primaryActions,
                icon: "starfolder"
            )

            BookmarkStatTile(
                title: "Bookmarks",
                value: bookmarks.count,
                tint: LColors.secondaryAccent,
                icon: "starmark"
            )

            BookmarkStatTile(
                title: "Favorites",
                value: favoriteBookmarkCount,
                tint: LColors.indicators,
                icon: "starfill"
            )
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var searchSection: some View {
        GlassCard {
            HStack(spacing: 10) {
                Image("searchsparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.white.opacity(0.45))

                TextField("Search folders", text: $searchText)
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
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1.2)
        )
        .padding(.horizontal, LSpacing.pageHorizontal)
        .onChange(of: searchText) { _, _ in
            visibleFolderCount = 5
        }
    }

    var folderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(visibleFolders.enumerated()), id: \.element.id) { index, folder in
                let accent = rotatingFolderAccent(at: index)

                GlassCard {
                    HStack(spacing: 14) {
                        Button {
                            if !isReorderMode {
                                editingFolder = folder
                            }
                        } label: {
                            FolderLiquidIcon(
                                iconId: folder.iconName.isEmpty ? "folder" : folder.iconName,
                                accent: accent
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isReorderMode)

                        if isReorderMode {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(folder.name.isEmpty ? "Untitled" : folder.name)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(accent)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.82)

                                    Text("Drag to change this folder’s position.")
                                        .font(.subheadline)
                                        .foregroundStyle(LColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                Image("settings")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(LColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onDrag {
                                draggedFolderID = folder.persistentModelID
                                return NSItemProvider(object: String(describing: folder.persistentModelID) as NSString)
                            }
                            .onDrop(of: [.text], delegate: FolderReorderDropDelegate(
                                targetFolder: folder,
                                folders: filteredFolders,
                                draggedFolderID: $draggedFolderID,
                                modelContext: modelContext
                            ))
                        } else {
                            NavigationLink {
                                BookmarkFolderDetailView(folder: folder)
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(folder.name.isEmpty ? "Untitled" : folder.name)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(accent)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.82)

                                        Text("Open this folder to view and manage its bookmarks.")
                                            .font(.subheadline)
                                            .foregroundStyle(LColors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer()

                                    Image("chevright")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundStyle(LColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .folderCardAccent(accent)
                // .premiumLocked removed as per instructions
                .contextMenu {
                    Button {
                        withAnimation {
                            isReorderMode = true
                            pendingReorderFolder = folder
                        }
                    } label: {
                        Label("Reorder", image: "settings")
                    }

                    if folder.systemKey != "inbox" {
                        Button(role: .destructive) {
                            folderToDelete = folder
                            showingDeleteFolderDialog = true
                        } label: {
                            Label("Delete", image: "trashfill")
                        }
                    }
                }
            }

            if filteredFolders.count > visibleFolderCount {
                HStack {
                    Spacer()

                    LoadMoreButton {
                        withAnimation {
                            visibleFolderCount += 5
                        }
                    }

                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

}

// MARK: - Computed Data

private extension BookmarksView {
    var inboxFolder: BookmarkFolder? {
        folders.first(where: { $0.systemKey == "inbox" })
    }

    var sortedFoldersForStrip: [BookmarkFolder] {
        folders.sorted {
            if $0.systemKey == "inbox" && $1.systemKey != "inbox" { return true }
            if $1.systemKey == "inbox" && $0.systemKey != "inbox" { return false }
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var filteredFolders: [BookmarkFolder] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuery = query.lowercased()
        guard !query.isEmpty else { return sortedFoldersForStrip }

        return sortedFoldersForStrip.filter { folder in
            let name = folder.name.lowercased()
            let systemKey = folder.systemKey.lowercased()
            return name.contains(normalizedQuery) || systemKey.contains(normalizedQuery)
        }
    }

    var visibleFolders: [BookmarkFolder] {
        Array(filteredFolders.prefix(visibleFolderCount))
    }

    var favoriteBookmarkCount: Int {
        bookmarks.filter(\.isFavorite).count
    }
}

// MARK: - Actions

private extension BookmarksView {
    func importPendingSharedBookmark() {
        SharedBookmarkImportManager.importPendingBookmark(modelContext: modelContext)
    }

    func repairDuplicateInboxesIfNeeded() {
        let inboxes = folders.filter { $0.systemKey == "inbox" }
        guard let canonicalInbox = inboxes.min(by: { $0.createdAt < $1.createdAt }) else { return }

        canonicalInbox.name = "Inbox"
        canonicalInbox.iconName = "inboxfill"
        canonicalInbox.sortOrder = 0

        let duplicates = inboxes.filter { $0.persistentModelID != canonicalInbox.persistentModelID }
        for duplicate in duplicates {
            for bookmark in bookmarks where bookmark.folder?.persistentModelID == duplicate.persistentModelID {
                bookmark.folder = canonicalInbox
                bookmark.updatedAt = Date()
            }
            modelContext.delete(duplicate)
        }

        canonicalInbox.updatedAt = Date()

        do {
            try modelContext.save()
            SharedFolderExportManager.exportFolders(modelContext: modelContext)
        } catch {
            print("Failed to repair duplicate Inbox folders: \(error)")
        }
    }

    func moveFolder(with draggedID: PersistentIdentifier, before targetFolder: BookmarkFolder, in sourceFolders: [BookmarkFolder]) {
        guard let fromIndex = sourceFolders.firstIndex(where: { $0.persistentModelID == draggedID }),
              let toIndex = sourceFolders.firstIndex(where: { $0.persistentModelID == targetFolder.persistentModelID }),
              fromIndex != toIndex else { return }

        var reordered = sourceFolders
        let moved = reordered.remove(at: fromIndex)
        reordered.insert(moved, at: toIndex)

        for (index, folder) in reordered.enumerated() {
            folder.sortOrder = folder.systemKey == "inbox" ? 0 : index + 1
            folder.updatedAt = Date()
        }

        do {
            try modelContext.save()
            SharedFolderExportManager.exportFolders(modelContext: modelContext)
        } catch {
            print("Failed to reorder folders: \(error)")
        }
    }

    func deleteFolder(_ folder: BookmarkFolder) {
        guard folder.systemKey != "inbox" else {
            folderToDelete = nil
            showingDeleteFolderDialog = false
            return
        }

        guard let inboxFolder else {
            folderToDelete = nil
            showingDeleteFolderDialog = false
            return
        }

        let bookmarksInFolder = bookmarks.filter { $0.folder?.persistentModelID == folder.persistentModelID }
        for bookmark in bookmarksInFolder {
            bookmark.folder = inboxFolder
            bookmark.updatedAt = Date()
        }

        modelContext.delete(folder)

        do {
            try modelContext.save()
            SharedFolderExportManager.exportFolders(modelContext: modelContext)
        } catch {
            print("Failed to delete folder: \(error)")
        }

        folderToDelete = nil
        showingDeleteFolderDialog = false
    }

    func resetReorderStateIfNeeded() {
        if !isReorderMode {
            draggedFolderID = nil
            pendingReorderFolder = nil
        }

        if !showingDeleteFolderDialog {
            folderToDelete = nil
        }
    }
}

// MARK: - Small UI Pieces

private extension BookmarksView {
    func rotatingFolderAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }
}

private struct FolderLiquidIcon: View {
    let iconId: String
    let accent: Color

    var body: some View {
        ZStack {
            BubblyTileSurface(tint: accent, cornerRadius: 19)
                .clipShape(Circle())

            MarklyIconView(iconId: iconId, size: 19)
                .foregroundStyle(LColors.primaryText)
        }
        .frame(width: 38, height: 38)
        .overlay(
            Circle()
                .strokeBorder(accent, lineWidth: 1.5)
        )
        .bubblyTileLift()
    }
}

private extension View {
    func folderCardAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}

private struct BookmarkStatTile: View {
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

// MARK: - Enums


private struct FolderReorderDropDelegate: DropDelegate {
    let targetFolder: BookmarkFolder
    let folders: [BookmarkFolder]
    @Binding var draggedFolderID: PersistentIdentifier?
    let modelContext: ModelContext

    func dropEntered(info: DropInfo) {
        guard let draggedFolderID,
              draggedFolderID != targetFolder.persistentModelID,
              let fromIndex = folders.firstIndex(where: { $0.persistentModelID == draggedFolderID }),
              let toIndex = folders.firstIndex(where: { $0.persistentModelID == targetFolder.persistentModelID }),
              fromIndex != toIndex else { return }

        var reordered = folders
        let moved = reordered.remove(at: fromIndex)
        reordered.insert(moved, at: toIndex)

        for (index, folder) in reordered.enumerated() {
            folder.sortOrder = folder.systemKey == "inbox" ? 0 : index + 1
            folder.updatedAt = Date()
        }

        do {
            try modelContext.save()
            SharedFolderExportManager.exportFolders(modelContext: modelContext)
        } catch {
            print("Failed to update folder order during drag: \(error)")
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedFolderID = nil
        return true
    }
}
