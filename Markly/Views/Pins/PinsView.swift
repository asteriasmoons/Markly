//
//  PinsView.swift
//  Markly
//

import SwiftUI
import SwiftData

struct PinsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var bookmarks: [BookmarkItem]
    @Query private var folders: [BookmarkFolder]
    @Query private var collections: [PinCollection]

    @State private var searchText = ""
    @State private var selectedBookmark: BookmarkItem?
    @State private var selectedCollection: PinCollection?
    @State private var showingCreateCollectionSheet = false
    @State private var draftCollectionName = ""
    @State private var selectedCollectionIcon = "pinfill"

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                headerSection

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        collectionsSection
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
        .navigationDestination(item: $selectedCollection) { collection in
            PinCollectionView(collection: collection)
        }
        .adaptiveSheet(isPresented: $showingCreateCollectionSheet) {
            createCollectionSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Sections

private extension PinsView {
    var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pins")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)

                Text("Build quick-access collections for your most important saved links.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                draftCollectionName = ""
                selectedCollectionIcon = "pinfill"
                showingCreateCollectionSheet = true
            } label: {
                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(LColors.indicators)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if sortedCollections.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center) {
                            sectionHeader(title: "Collections", icon: "pinfill")
                            Spacer()
                        }

                        Text("Create pin collections for your most-used bookmark groups.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .pinsBoxBorder(pinsBoxAccent(at: 0))
            } else {
                ForEach(Array(collectionGroups.enumerated()), id: \.offset) { index, group in
                    collectionGroupCard(group, index: index)
                }
            }
        }
    }
    func collectionGroupCard(_ collections: [PinCollection], index: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    sectionHeader(
                        title: index == 0 ? "Collections" : "Collections \(index + 1)",
                        icon: "pinfill"
                    )

                    Spacer()
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(Array(collections.enumerated()), id: \.element.id) { collectionIndex, collection in
                        Button {
                            selectedCollection = collection
                        } label: {
                            collectionCard(
                                collection,
                                index: index * 4 + collectionIndex
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .pinsBoxBorder(pinsBoxAccent(at: index))
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

                TextField("Search pinned bookmarks", text: $searchText)
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
        .pinsBoxBorder(LColors.secondaryAccent)
    }

    var pinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                sectionHeader(title: "All Pins", icon: "starmark")

                Spacer()

                Text("\(filteredPins.count)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.07), in: Capsule())
            }
            .padding(.horizontal, 2)

            if filteredPins.isEmpty {
                emptyStateCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(filteredPins.enumerated()), id: \.element.id) { index, bookmark in
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

                Text(pinnedBookmarks.isEmpty ? "No pins yet" : "No matching pins")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(pinnedBookmarks.isEmpty ? "Pin bookmarks from your library and they’ll show up here." : "Try clearing the search field.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .pinsBoxBorder(LColors.indicators)
    }

    var createCollectionSheet: some View {
        PinCollectionEditorSheet(
            title: "New Collection",
            subtitle: "Name your collection and choose an icon for it.",
            actionTitle: "Create Collection",
            collectionName: $draftCollectionName,
            selectedIcon: $selectedCollectionIcon,
            onClose: {
                showingCreateCollectionSheet = false
            },
            onSave: {
                createCollection()
            }
        )
    }
}

// MARK: - Cards

private extension PinsView {
    func collectionCard(_ collection: PinCollection, index: Int) -> some View {
        let accent = rotatingCollectionAccent(at: index)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ZStack {
                    BubblyTileSurface(tint: accent, cornerRadius: 19)
                        .clipShape(Circle())

                    MarklyIconView(iconId: collection.iconName, size: 16)
                        .foregroundStyle(LColors.primaryText)
                }
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .strokeBorder(accent, lineWidth: 1.5)
                )
                .bubblyTileLift()

                Spacer()

                Text("\(collection.bookmarkCount)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.displayTitle)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
                    .lineLimit(1)

                Text(collection.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Pinned bookmark group" : collection.notes)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }

    func pinCard(_ bookmark: BookmarkItem, index: Int) -> some View {
        GlassCard {
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

                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LColors.textSecondary)
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
                            PinTagPill(text: tag)
                        }
                    }
                }
            }
        }
        .pinsBoxBorder(pinsBoxAccent(at: pinsBoxOffsetAfterCollections + 2 + index))
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

    func rotatingCollectionAccent(at index: Int) -> Color {
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

// MARK: - Actions

private extension PinsView {
    func createCollection() {
        let title = draftCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let collection = PinCollection(
            title: title,
            iconName: selectedCollectionIcon,
            sortOrder: nextCollectionSortOrder
        )

        modelContext.insert(collection)

        do {
            try modelContext.save()
            selectedCollection = collection
            showingCreateCollectionSheet = false
            draftCollectionName = ""
            selectedCollectionIcon = "pinfill"
        } catch {
            print("Failed to create pin collection: \(error)")
        }
    }
}

// MARK: - Data

private extension PinsView {
    var sortedFolders: [BookmarkFolder] {
        folders.sorted {
            if $0.systemKey == "inbox" { return true }
            if $1.systemKey == "inbox" { return false }

            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }

            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var collectionGroups: [[PinCollection]] {
        stride(from: 0, to: sortedCollections.count, by: 4).map { startIndex in
            let endIndex = min(startIndex + 4, sortedCollections.count)
            return Array(sortedCollections[startIndex..<endIndex])
        }
    }

    var sortedCollections: [PinCollection] {
        collections.sorted {
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }

            return $0.createdAt < $1.createdAt
        }
    }

    var nextCollectionSortOrder: Int {
        (collections.map { $0.sortOrder }.max() ?? -1) + 1
    }

    var pinsBoxOffsetAfterCollections: Int {
        if sortedCollections.isEmpty {
            return 1
        }

        return collectionGroups.count
    }

    func pinsBoxAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    var pinnedBookmarks: [BookmarkItem] {
        bookmarks
            .filter { $0.isPinned }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var filteredPins: [BookmarkItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else { return pinnedBookmarks }

        return pinnedBookmarks.filter { bookmark in
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
}

// MARK: - Supporting Views

private struct PinTagPill: View {
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
    func pinsBoxBorder(_ accent: Color) -> some View {
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
