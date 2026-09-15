//
//  AddEditBookmarkView.swift
//  Markly
//
//  Created by Asteria Moon on 3/19/26.
//

import SwiftUI
import SwiftData
import LinkPresentation
import UniformTypeIdentifiers
import UIKit

struct AddEditBookmarkView: View {
    @Environment(\.modelContext) private var modelContext

    let bookmark: BookmarkItem?   // nil = create mode
    let folders: [BookmarkFolder]
    let initialFolder: BookmarkFolder?
    let onClose: () -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var link: String = ""
    @State private var tagInput: String = ""
    @State private var tagValues: [String] = []
    @State private var selectedFolder: BookmarkFolder? = nil

    @State private var duplicateWarning: String = ""

    init(
        bookmark: BookmarkItem?,
        folders: [BookmarkFolder],
        initialFolder: BookmarkFolder? = nil,
        onClose: @escaping () -> Void
    ) {
        self.bookmark = bookmark
        self.folders = folders
        self.initialFolder = initialFolder
        self.onClose = onClose
    }

    var isEditing: Bool {
        bookmark != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MarklyBackground()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        fields
                        actionRow
                    }
                    .padding(22)
                    .padding(.bottom, 24)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            loadData()
        }
    }
}

// MARK: - UI

private extension AddEditBookmarkView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 14) {
                Text(isEditing ? "Edit Bookmark" : "Add Bookmark")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onClose) {
                    Image("xmark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(LColors.secondaryAccent)
                }
                .buttonStyle(.plain)
            }

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var headerSubtitle: String {
        if isEditing {
            return "Update your saved link, notes, and organization."
        }

        if let initialFolder {
            return "Save a link directly into \(initialFolder.name.isEmpty ? "this folder" : initialFolder.name)."
        }

        return "Save a link with context so it stays meaningful later."
    }

    var fields: some View {
        VStack(alignment: .leading, spacing: 12) {
            bookmarkFieldSection(title: "Title", accent: bookmarkFieldAccent(at: 0)) {
                GlassTextField(
                    placeholder: "Name this bookmark",
                    text: $title,
                    borderColor: bookmarkFieldAccent(at: 0),
                    borderLineWidth: 1.2
                )
            }

            bookmarkFieldSection(title: "Description", accent: bookmarkFieldAccent(at: 1)) {
                GlassTextEditor(
                    placeholder: "Add a short description",
                    text: $description,
                    minHeight: 120,
                    borderColor: bookmarkFieldAccent(at: 1),
                    borderLineWidth: 1.2
                )
            }

            bookmarkFieldSection(title: "Link", accent: bookmarkFieldAccent(at: 2)) {
                GlassTextField(
                    placeholder: "https://example.com",
                    text: $link,
                    borderColor: bookmarkFieldAccent(at: 2),
                    borderLineWidth: 1.2
                )
                .onChange(of: link) { _, newValue in
                    duplicateWarning = duplicateWarningMessage(for: newValue)
                }

                if !duplicateWarning.isEmpty {
                    Text(duplicateWarning)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(LColors.warning)
                }
            }

            bookmarkFieldSection(title: "Tags", accent: bookmarkFieldAccent(at: 3)) {
                tagEditor(accent: bookmarkFieldAccent(at: 3))
            }

            if shouldShowFolderPicker {
                bookmarkFieldSection(title: "Folder", accent: bookmarkFieldAccent(at: 4)) {
                    folderPicker(accent: bookmarkFieldAccent(at: 4))
                }
            }
        }
    }

    var shouldShowFolderPicker: Bool {
        isEditing || initialFolder == nil
    }

    func tagEditor(accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !tagValues.isEmpty {
                FlowLayout(spacing: 8, rowSpacing: 8) {
                    ForEach(Array(tagValues.enumerated()), id: \.offset) { index, tag in
                        BookmarkTagChip(
                            title: tag,
                            tint: bookmarkFieldAccent(at: index)
                        ) {
                            tagValues.remove(at: index)
                        }
                    }
                }
            }

            GlassTextField(
                placeholder: "Type a tag and press return",
                text: $tagInput,
                borderColor: accent,
                borderLineWidth: 1.2
            )
            .submitLabel(.done)
            .onSubmit {
                addTagFromInput()
            }
        }
    }

    func bookmarkFieldSection<Content: View>(
        title: String,
        accent: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(accent)

                content()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }

    func folderPicker(accent: Color) -> some View {
        Menu {
            ForEach(folders) { folder in
                Button(folder.name.isEmpty ? "Untitled" : folder.name) {
                    selectedFolder = folder
                }
            }
        } label: {
            HStack {
                Text(selectedFolder?.name ?? "Inbox")
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Image("chevdown")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(LColors.textSecondary)
            }
            .padding(12)
            .background(Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .strokeBorder(accent, lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: LSpacing.inputRadius))
        }
        .buttonStyle(.plain)
    }

    var actionRow: some View {
        HStack {
            BookmarkCancelButton(
                title: "Cancel",
                icon: "xmark"
            ) {
                onClose()
            }

            Spacer()

            BookmarkSaveButton(
                title: isEditing ? "Save Changes" : "Save Bookmark",
                icon: "checkwavy"
            ) {
                save()
            }
        }
    }

    func bookmarkFieldAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    func addTagFromInput() {
        let cleaned = tagInput
            .replacingOccurrences(of: ",", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return }

        tagValues.append(cleaned)
        tagInput = ""
    }

    func currentTagValuesForSave() -> [String] {
        var values = tagValues
        let pending = tagInput
            .replacingOccurrences(of: ",", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !pending.isEmpty {
            values.append(pending)
        }

        return values
    }
}

// MARK: - Supporting Views

private struct BookmarkTagChip: View {
    let title: String
    let tint: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .lineLimit(1)

            Button(action: onRemove) {
                Image("xmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(LColors.primaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 999)
        }
        .bubblyTileLift()
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let rows = rows(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.reduce(CGFloat.zero) { total, row in
            total + row.height
        } + CGFloat(max(rows.count - 1, 0)) * rowSpacing

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = rows(
            proposal: ProposedViewSize(width: bounds.width, height: proposal.height),
            subviews: subviews
        )

        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for element in row.elements {
                element.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(element.size)
                )

                x += element.size.width + spacing
            }

            y += row.height + rowSpacing
        }
    }

    private func rows(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> [FlowRow] {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var rows: [FlowRow] = []
        var current = FlowRow()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needsNewRow = !current.elements.isEmpty
            && current.width + spacing + size.width > maxWidth

            if needsNewRow {
                rows.append(current)
                current = FlowRow()
            }

            current.append(subview: subview, size: size, spacing: spacing)
        }

        if !current.elements.isEmpty {
            rows.append(current)
        }

        return rows
    }
}

private struct FlowRow {
    var elements: [FlowElement] = []
    var width: CGFloat = 0
    var height: CGFloat = 0

    mutating func append(
        subview: LayoutSubviews.Element,
        size: CGSize,
        spacing: CGFloat
    ) {
        width += elements.isEmpty ? size.width : spacing + size.width
        height = max(height, size.height)
        elements.append(FlowElement(subview: subview, size: size))
    }
}

private struct FlowElement {
    let subview: LayoutSubviews.Element
    let size: CGSize
}

private struct BookmarkSaveButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)

                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(LColors.background)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: LSpacing.buttonRadius)
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }
}

private struct BookmarkCancelButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)

                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(LColors.primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: LSpacing.buttonRadius)
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Logic

private extension AddEditBookmarkView {
    func loadData() {
        guard let bookmark else {
            selectedFolder = initialFolder ?? folders.first(where: { $0.systemKey == "inbox" })
            return
        }

        title = bookmark.title
        description = bookmark.bookmarkDescription
        link = bookmark.link
        tagValues = bookmark.tags
        tagInput = ""
        selectedFolder = bookmark.folder
    }

    func save() {
        let currentTags = currentTagValuesForSave()
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLink = link.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedTags = currentTags.joined(separator: ", ")

        guard !cleanedTitle.isEmpty, !cleanedLink.isEmpty else { return }

        if let bookmark {
            bookmark.title = cleanedTitle
            bookmark.bookmarkDescription = cleanedDescription
            bookmark.link = cleanedLink
            bookmark.tagsRaw = cleanedTags
            bookmark.folder = selectedFolder
            bookmark.updatedAt = Date()

            do {
                try modelContext.save()
            } catch {
                print("Failed to save bookmark: \(error)")
                return
            }

            Task {
                await fetchMetadataAndApply(to: bookmark, link: cleanedLink)
                await MainActor.run {
                    onClose()
                }
            }
        } else {
            let new = BookmarkItem(
                title: cleanedTitle,
                bookmarkDescription: cleanedDescription,
                link: cleanedLink,
                tagsRaw: cleanedTags,
                notes: "",
                isFavorite: false,
                iconData: nil,
                thumbnailData: nil,
                createdAt: Date(),
                updatedAt: Date(),
                folder: selectedFolder
            )
            modelContext.insert(new)

            do {
                try modelContext.save()
            } catch {
                print("Failed to save bookmark: \(error)")
                return
            }

            Task {
                await fetchMetadataAndApply(to: new, link: cleanedLink)
                await MainActor.run {
                    onClose()
                }
            }
        }
    }

    @MainActor
    func fetchMetadataAndApply(to bookmark: BookmarkItem, link: String) async {
        guard let url = normalizedURL(from: link) else { return }

        do {
            let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)

            let fetchedIconData = await loadData(from: metadata.iconProvider)
            let fetchedThumbnailData = await loadData(from: metadata.imageProvider)

            if let fetchedIconData {
                bookmark.iconData = fetchedIconData
            }

            if let fetchedThumbnailData {
                bookmark.thumbnailData = fetchedThumbnailData
            }

            if bookmark.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let fetchedTitle = metadata.title,
               !fetchedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                bookmark.title = fetchedTitle
            }

            bookmark.updatedAt = Date()
            try modelContext.save()
        } catch {
            print("Failed to fetch bookmark metadata: \(error)")
        }
    }

    func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let directURL = URL(string: trimmed), directURL.scheme != nil {
            return directURL
        }

        return URL(string: "https://\(trimmed)")
    }

    func loadData(from itemProvider: NSItemProvider?) async -> Data? {
        guard let itemProvider else { return nil }

        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            let image: UIImage? = await withCheckedContinuation { continuation in
                itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    continuation.resume(returning: object as? UIImage)
                }
            }

            if let image {
                return image.pngData()
            }
        }

        let supportedTypes = [UTType.png.identifier, UTType.jpeg.identifier, UTType.image.identifier]

        for typeIdentifier in supportedTypes {
            if itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                let item: NSSecureCoding? = await withCheckedContinuation { continuation in
                    itemProvider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                        continuation.resume(returning: item)
                    }
                }

                if let data = item as? Data {
                    return data
                }

                if let url = item as? URL {
                    return try? Data(contentsOf: url)
                }

                if let nsURL = item as? NSURL, let url = nsURL as URL? {
                    return try? Data(contentsOf: url)
                }
            }
        }

        return nil
    }

    func duplicateWarningMessage(for link: String) -> String {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return "" }

        return "" // Keep simple here; your main view already handles full detection
    }
}

fileprivate func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
