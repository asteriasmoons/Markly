//
//  PinCollectionView.swift
//  Markly
//

import SwiftUI
import SwiftData

struct PinCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var collection: PinCollection

    @Query private var allBookmarks: [BookmarkItem]

    @State private var searchText = ""
    @State private var selectedBookmark: BookmarkItem?
    @State private var showingAddPinsSheet = false
    @State private var showingEditCollectionSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var draftCollectionName = ""
    @State private var draftCollectionIcon = "pinfill"

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                headerSection

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        collectionSummaryCard
                        searchCard
                        pinsSection
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.bottom, 120)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedBookmark) { bookmark in
            BookmarkDetailView(
                bookmark: bookmark,
                availableFolders: sortedFolders
            )
        }
        .adaptiveSheet(isPresented: $showingAddPinsSheet) {
            addPinsSheet
                .presentationDetents([.height(620)])
                .presentationDragIndicator(.visible)
        }
        .adaptiveSheet(isPresented: $showingEditCollectionSheet) {
            editCollectionSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Delete Collection",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Collection", role: .destructive) {
                deleteCollection()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the collection, but it will not delete the bookmarks inside it.")
        }
    }
}

// MARK: - Sections

private extension PinCollectionView {
    var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(collection.displayTitle)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("\(collection.bookmarkCount) pinned bookmark\(collection.bookmarkCount == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

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
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var collectionSummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: 23)
                            .clipShape(Circle())

                        MarklyIconView(iconId: collection.iconName, size: 20)
                            .foregroundStyle(LColors.primaryText)
                    }
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle()
                            .strokeBorder(LColors.primaryActions, lineWidth: 1.5)
                    )
                    .bubblyTileLift()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(collection.displayTitle)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(collection.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "A focused space for related pinned links." : collection.notes)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        showingAddPinsSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)

                            Text("Add Pins")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: LSpacing.buttonRadius)
                        }
                        .bubblyTileLift()
                    }
                    .buttonStyle(.plain)

                    Button {
                        draftCollectionName = collection.title
                        draftCollectionIcon = collection.iconName
                        showingEditCollectionSheet = true
                    } label: {
                        Image("settings")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(LColors.primaryText)
                            .frame(width: 46, height: 46)
                            .background {
                                BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: LSpacing.buttonRadius)
                            }
                            .bubblyTileLift()
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image("trashfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(LColors.primaryText)
                            .frame(width: 46, height: 46)
                            .background {
                                BubblyTileSurface(tint: LColors.indicators, cornerRadius: LSpacing.buttonRadius)
                            }
                            .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .collectionDetailBorder(LColors.primaryActions)
    }

    var searchCard: some View {
        GlassCard {
            HStack(spacing: 10) {
                Image("searchsparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.secondaryAccent)

                TextField("Search this collection", text: $searchText)
                    .foregroundStyle(LColors.textPrimary)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .tint(LColors.secondaryAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .fill(Color.white.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .strokeBorder(LColors.secondaryAccent, lineWidth: 1.2)
            )
        }
        .collectionDetailBorder(LColors.secondaryAccent)
    }

    var pinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Pins", icon: "starmark")

                Spacer()

                Text("\(filteredCollectionBookmarks.count)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.07), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 2)

            if filteredCollectionBookmarks.isEmpty {
                emptyStateCard
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(Array(filteredCollectionBookmarks.enumerated()), id: \.element.id) { index, bookmark in
                        Button {
                            selectedBookmark = bookmark
                        } label: {
                            pinCard(bookmark, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var emptyStateCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image("starmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(LColors.indicators)

                Text(collectionBookmarks.isEmpty ? "No pins in this collection" : "No matching pins")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(collectionBookmarks.isEmpty ? "Add pinned bookmarks to this collection to build a focused shortcut space." : "Try clearing the search field.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .collectionDetailBorder(LColors.indicators)
    }
}

// MARK: - Add Pins Sheet

private extension PinCollectionView {
    var editCollectionSheet: some View {
        PinCollectionEditorSheet(
            title: "Edit Collection",
            subtitle: "Update this collection name and icon.",
            actionTitle: "Save Collection",
            collectionName: $draftCollectionName,
            selectedIcon: $draftCollectionIcon,
            onClose: {
                showingEditCollectionSheet = false
            },
            onSave: {
                saveCollectionEdits()
            }
        )
    }

    var addPinsSheet: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Add Pins")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.secondaryAccent)

                    Spacer()

                    Button {
                        showingAddPinsSheet = false
                    } label: {
                        Image("xmark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(LColors.secondaryAccent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.bottom, 14)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose pinned bookmarks to include in this collection.")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .padding(.horizontal, LSpacing.pageHorizontal)

                        if availablePinnedBookmarks.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Image("pinfill")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                        .foregroundStyle(LColors.secondaryAccent)

                                    Text("No available pins")
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text("Pin bookmarks from your library first, then add them to this collection.")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .collectionDetailBorder(LColors.primaryActions)
                            .padding(.horizontal, LSpacing.pageHorizontal)
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                spacing: 12
                            ) {
                                ForEach(availablePinnedBookmarks) { bookmark in
                                    Button {
                                        toggleBookmark(bookmark)
                                    } label: {
                                        selectableBookmarkRow(bookmark)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, LSpacing.pageHorizontal)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .padding(.top, 22)
        }
    }
}

// MARK: - Cards

private extension PinCollectionView {
    func pinCard(_ bookmark: BookmarkItem, index: Int) -> some View {
        let accent = collectionDetailPinAccent(at: index)

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    bookmarkIcon(bookmark)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(bookmark.title.isEmpty ? "Untitled Bookmark" : bookmark.title)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(bookmark.link)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        removeBookmark(bookmark)
                    } label: {
                        Image("xmark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                if !bookmark.bookmarkDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(bookmark.bookmarkDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(3)
                }

                if !bookmark.tags.isEmpty {
                    FlowLayout(spacing: 7) {
                        ForEach(bookmark.tags, id: \.self) { tag in
                            PinCollectionTagPill(text: tag)
                        }
                    }
                }
            }
        }
        .collectionDetailBorder(accent)
    }

    func selectableBookmarkRow(_ bookmark: BookmarkItem) -> some View {
        let isIncluded = collectionBookmarks.contains {
            $0.persistentModelID == bookmark.persistentModelID
        }

        return HStack(spacing: 12) {
            bookmarkIcon(bookmark)

            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title.isEmpty ? "Untitled Bookmark" : bookmark.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(bookmark.link)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(isIncluded ? "checkwavy" : "addwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: isIncluded ? 18 : 20, height: isIncluded ? 18 : 20)
                .foregroundStyle(isIncluded ? AnyShapeStyle(LColors.indicators) : AnyShapeStyle(LColors.textSecondary))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isIncluded ? Color.white.opacity(0.10) : Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isIncluded ? AnyShapeStyle(LColors.indicators) : AnyShapeStyle(Color.white.opacity(0.11)),
                    lineWidth: isIncluded ? 1.4 : 1
                )
        )
    }

    func bookmarkIcon(_ bookmark: BookmarkItem) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .strokeBorder(LColors.indicators, lineWidth: 1.5)
                )

            if let iconData = bookmark.iconData,
               let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
            } else {
                Image("starmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.indicators)
            }
        }
    }

    func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: icon == "pinfill" ? 21 : 17, height: icon == "pinfill" ? 21 : 17)
                .foregroundStyle(LColors.secondaryAccent)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    func collectionDetailPinAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.indicators
        case 1:
            return LColors.primaryActions
        default:
            return LColors.secondaryAccent
        }
    }
}

// MARK: - Actions

private extension PinCollectionView {
    func toggleBookmark(_ bookmark: BookmarkItem) {
        if collectionBookmarks.contains(where: { $0.persistentModelID == bookmark.persistentModelID }) {
            removeBookmark(bookmark)
        } else {
            addBookmark(bookmark)
        }
    }

    func addBookmark(_ bookmark: BookmarkItem) {
        var current = collection.bookmarks ?? []
        guard !current.contains(where: { $0.persistentModelID == bookmark.persistentModelID }) else { return }

        current.append(bookmark)
        collection.bookmarks = current
        collection.touch()

        bookmark.isPinned = true
        bookmark.updatedAt = Date()

        save()
    }

    func removeBookmark(_ bookmark: BookmarkItem) {
        collection.bookmarks = collectionBookmarks.filter {
            $0.persistentModelID != bookmark.persistentModelID
        }
        collection.touch()
        save()
    }

    func deleteCollection() {
        modelContext.delete(collection)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete pin collection: \(error)")
        }
    }

    func saveCollectionEdits() {
        let title = draftCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        collection.title = title
        collection.iconName = draftCollectionIcon
        collection.touch()

        do {
            try modelContext.save()
            showingEditCollectionSheet = false
        } catch {
            print("Failed to save collection edits: \(error)")
        }
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save pin collection changes: \(error)")
        }
    }
}

// MARK: - Data

private extension PinCollectionView {
    var sortedFolders: [BookmarkFolder] {
        let folderSet = allBookmarks.compactMap { $0.folder }

        return folderSet.sorted {
            if $0.systemKey == "inbox" { return true }
            if $1.systemKey == "inbox" { return false }

            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }

            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var collectionBookmarks: [BookmarkItem] {
        (collection.bookmarks ?? [])
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var filteredCollectionBookmarks: [BookmarkItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else { return collectionBookmarks }

        return collectionBookmarks.filter { bookmark in
            let searchable = [
                bookmark.title,
                bookmark.link,
                bookmark.bookmarkDescription,
                bookmark.notes,
                bookmark.folder?.name ?? "",
                bookmark.tags.joined(separator: " ")
            ]
            .joined(separator: " ")
            .lowercased()

            return searchable.contains(query)
        }
    }

    var availablePinnedBookmarks: [BookmarkItem] {
        allBookmarks
            .filter { $0.isPinned }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Supporting Views

private struct PinCollectionTagPill: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image("tagsparkle")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .foregroundStyle(.white.opacity(0.86))

            Text(text)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(LColors.glassSurface2)
        )
        .overlay(
            Capsule()
                .strokeBorder(LColors.glassBorder, lineWidth: 1)
        )
    }
}

private extension View {
    func collectionDetailBorder(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
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
