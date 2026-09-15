//
//  BookmarkDetailView.swift
//  Markly
//

import SwiftUI
import SwiftData
import UIKit

struct BookmarkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let bookmark: BookmarkItem
    let availableFolders: [BookmarkFolder]

    @Query(sort: \BookmarkNote.createdAt, order: .reverse)
    private var allNotes: [BookmarkNote]

    @State private var selectedTab: BookmarkDetailTab = .notes
    @State private var notesText: String = ""
    @State private var showDeleteDialog: Bool = false
    @State private var selectedNote: BookmarkNote? = nil
    @State private var showEditBookmarkSheet: Bool = false
    @State private var showReaderView: Bool = false

    var body: some View {
        ZStack {
            MarklyBackground()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center) {
                        Text(pageTitle)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.secondaryAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Spacer()

                        readerButton

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
                    .frame(maxWidth: .infinity, alignment: .leading)

                    headerCard
                    tabPickerCard

                    switch selectedTab {
                    case .notes:
                        notesCard

                        if !savedNotes.isEmpty {
                            savedNotesSection
                        }
                    case .preview:
                        previewCard
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 8)
                .padding(.bottom, 190)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            notesText = ""
            migrateLegacyNoteIfNeeded()
        }
        .adaptiveSheet(item: $selectedNote) { note in
            fullNoteSheet(note)
        }
        .adaptiveSheet(isPresented: $showEditBookmarkSheet) {
            AddEditBookmarkView(
                bookmark: bookmark,
                folders: availableFolders,
                onClose: {
                    showEditBookmarkSheet = false
                }
            )
        }
        .fullScreenCover(isPresented: $showReaderView) {
            if let validPreviewURL {
                ReaderView(sourceURL: validPreviewURL)
            }
        }
        .alert("Delete Bookmark", isPresented: $showDeleteDialog) {
            Button("Delete", role: .destructive) {
                deleteBookmark()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this bookmark? This cannot be undone.")
        }
    }
}

// MARK: - Main Sections

private extension BookmarkDetailView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            overviewCard
            actionCard
        }
    }

    var readerButton: some View {
        Button {
            showReaderView = validPreviewURL != nil
        } label: {
            Image("ebook")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(LColors.primaryActions)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .opacity(validPreviewURL == nil ? 0.45 : 1)
        .disabled(validPreviewURL == nil)
        .accessibilityLabel("Open Reader")
    }

    var overviewCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                OverviewInfoTile(
                    label: "Folder",
                    value: pageTitle,
                    icon: "openfolder",
                    tint: LColors.primaryActions
                )

                if !bookmark.tags.isEmpty {
                    tagTiles
                }

                if !bookmarkDescriptionText.isEmpty {
                    OverviewInfoTile(
                        label: "Description",
                        value: bookmarkDescriptionText,
                        icon: "blankpages",
                        tint: LColors.indicators,
                        allowsMultilineValue: true
                    )
                }

                if !bookmarkLinkText.isEmpty {
                    OverviewInfoTile(
                        label: "Link",
                        value: bookmarkLinkText,
                        icon: "link",
                        tint: LColors.raisedSurfaces,
                        allowsMultilineValue: true,
                        allowsTextSelection: true
                    )
                }
            }
        }
        .bookmarkDetailCardBorder(LColors.primaryActions)
    }

    var tagTiles: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(tagRows.enumerated()), id: \.offset) { _, row in
                if row.count == 1, let tag = row.first {
                    OverviewInfoTile(
                        label: "Tag",
                        value: tag,
                        icon: "tagsparkle",
                        tint: LColors.secondaryAccent
                    )
                } else {
                    HStack(spacing: 10) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, tag in
                            OverviewInfoTile(
                                label: "Tag",
                                value: tag,
                                icon: "tagsparkle",
                                tint: LColors.secondaryAccent
                            )
                        }
                    }
                }
            }
        }
    }

    var tabPickerCard: some View {
        GlassCard(padding: 14) {
            Picker("Bookmark Tab", selection: $selectedTab) {
                ForEach(BookmarkDetailTab.allCases) { tab in
                    Text(tab.label).tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
        .bookmarkDetailCardBorder(LColors.indicators)
    }

    var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeaderInline(title: "Notes", icon: "sticky")

                    Spacer()

                    Text(savedNotes.isEmpty ? "Empty" : "\(savedNotes.count) Saved")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LColors.textSecondary)
                }

                LButton(title: "Save", icon: "savesparkle", style: .primary) {
                    saveNote()
                }
                .opacity(notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                .disabled(notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                ZStack(alignment: .topLeading) {
                    if notesText.isEmpty {
                        Text("Add your thoughts, takeaways, quotes, reminders, or anything else you want to remember about this link.")
                            .foregroundStyle(LColors.textSecondary.opacity(0.55))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $notesText)
                        .foregroundStyle(LColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .frame(minHeight: 240)
                .background(
                    RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                        .fill(LColors.raisedSurfaces)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                        .strokeBorder(LColors.indicators, lineWidth: 1.2)
                )
                .clipShape(RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous))

            }
        }
        .bookmarkDetailCardBorder(LColors.indicators)
    }

    var savedNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderInline(title: "Saved Notes", icon: "starmark")

                Spacer()

                Text("\(savedNotes.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(LColors.background)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(LColors.indicators, in: Capsule())
            }

            savedNotesGrid
        }
    }

    var savedNotesGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(savedNotes) { note in
                Button {
                    selectedNote = note
                } label: {
                    NotePreviewCard(note: note)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var previewCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeaderInline(title: "Preview", icon: "linkcircle")

                    Spacer()

                    if validPreviewURL != nil {
                        LButton(title: "Open", icon: "browsericon", style: .secondary) {
                            openInSystemBrowser()
                        }
                    }
                }

                if let validPreviewURL {
                    BookmarkWebView(url: validPreviewURL)
                        .frame(minHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: LSpacing.cardRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: LSpacing.cardRadius)
                                .stroke(LColors.glassBorder, lineWidth: 1)
                        )
                } else {
                    invalidLinkState
                }
            }
        }
    }

    var invalidLinkState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("xmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(LColors.textSecondary)

            Text("This link can’t be previewed")
                .font(.headline)
                .foregroundStyle(.white)

            Text("The saved link looks incomplete or invalid. You can still open it externally after fixing the URL.")
                .font(.subheadline)
                .foregroundStyle(LColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: LSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LSpacing.cardRadius)
                .stroke(LColors.glassBorder, lineWidth: 1)
        )
    }

    var actionCard: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 8) {
                moveMenu

                Button {
                    openInSystemBrowser()
                } label: {
                    DetailActionLiquidButton(
                        title: "Open",
                        icon: "browsericon",
                        tint: LColors.secondaryAccent
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showDeleteDialog = true
                } label: {
                    DetailActionLiquidButton(
                        title: "Delete",
                        icon: "trashfill",
                        tint: LColors.indicators
                    )
                }
                .buttonStyle(.plain)

                favoriteButton

                editButton

                Spacer(minLength: 0)
            }
        }
        .bookmarkDetailCardBorder(LColors.secondaryAccent)
    }

    var favoriteButton: some View {
        Button {
            toggleFavorite()
        } label: {
            Image("starfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(bookmark.isFavorite ? LColors.indicators : LColors.textSecondary)
                .frame(width: 38, height: 38)
                .background(
                    bookmark.isFavorite ? LColors.indicators.opacity(0.18) : Color.white.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                        .stroke(bookmark.isFavorite ? LColors.indicators.opacity(0.72) : LColors.glassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    var editButton: some View {
        Button {
            showEditBookmarkSheet = true
        } label: {
            Image("pencil")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LColors.primaryText)
                .frame(width: 38, height: 38)
                .background {
                    BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: LSpacing.buttonRadius)
                }
                .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }

    var moveMenu: some View {
        Menu {
            ForEach(availableFolders) { folder in
                Button(folder.name.isEmpty ? "Untitled" : folder.name) {
                    moveToFolder(folder)
                }
            }
        } label: {
            DetailActionLiquidButton(
                title: "Move",
                icon: "openfolder",
                tint: LColors.primaryActions
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Computed

private extension BookmarkDetailView {
    var pageTitle: String {
        folderName ?? "Inbox"
    }

    var bookmarkDescriptionText: String {
        bookmark.bookmarkDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var bookmarkLinkText: String {
        bookmark.link.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var tagRows: [[String]] {
        let tags = bookmark.tags
        return stride(from: 0, to: tags.count, by: 2).map { index in
            Array(tags[index..<min(index + 2, tags.count)])
        }
    }

    var validPreviewURL: URL? {
        let trimmed = bookmark.link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let direct = URL(string: trimmed), direct.scheme != nil {
            return direct
        }

        return URL(string: "https://\(trimmed)")
    }

    var folderName: String? {
        bookmark.folder?.name.isEmpty == false ? bookmark.folder?.name : "Inbox"
    }

    var savedNotes: [BookmarkNote] {
        allNotes
            .filter { $0.bookmark?.persistentModelID == bookmark.persistentModelID }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Actions

private extension BookmarkDetailView {
    func saveNote() {
        let cleaned = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        let note = BookmarkNote(
            content: cleaned,
            createdAt: Date(),
            updatedAt: Date(),
            bookmark: bookmark
        )
        modelContext.insert(note)

        bookmark.notes = legacyNotesSummary(including: cleaned)
        bookmark.updatedAt = Date()

        do {
            try modelContext.save()
            notesText = ""
        } catch {
            print("Failed to save bookmark notes: \(error)")
        }
    }

    func migrateLegacyNoteIfNeeded() {
        let cleaned = bookmark.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, savedNotes.isEmpty else { return }

        let note = BookmarkNote(
            content: cleaned,
            createdAt: bookmark.updatedAt,
            updatedAt: bookmark.updatedAt,
            bookmark: bookmark
        )
        modelContext.insert(note)

        do {
            try modelContext.save()
        } catch {
            print("Failed to migrate bookmark notes: \(error)")
        }
    }

    func legacyNotesSummary(including newContent: String) -> String {
        ([newContent] + savedNotes.map(\.content))
            .joined(separator: "\n\n")
    }

    func toggleFavorite() {
        bookmark.isFavorite.toggle()
        bookmark.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to toggle bookmark favorite: \(error)")
        }
    }

    func moveToFolder(_ folder: BookmarkFolder) {
        bookmark.folder = folder
        bookmark.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to move bookmark to folder: \(error)")
        }
    }

    func deleteBookmark() {
        savedNotes.forEach { note in
            modelContext.delete(note)
        }
        modelContext.delete(bookmark)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete bookmark: \(error)")
        }
    }

    func openInSystemBrowser() {
        guard let url = validPreviewURL else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #endif
    }

    func labelText(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(LColors.textSecondary)
            .tracking(0.5)
    }

    func fullNoteSheet(_ note: BookmarkNote) -> some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                MarklySheetHeader(title: "Note", onClose: {
                    selectedNote = nil
                })
                .padding(.horizontal, LSpacing.pageHorizontal)

                ScrollView(.vertical, showsIndicators: true) {
                    Text(note.content)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.primaryText)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(LColors.raisedSurfaces, in: RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous)
                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, LSpacing.pageHorizontal)
                        .padding(.bottom, 30)
                }
            }
            .padding(.top, 22)
        }
    }
}

// MARK: - Small Supporting Views

private struct SectionHeaderInline: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.secondaryAccent)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

private struct DetailActionLiquidButton: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)

            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(LColors.primaryText)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: LSpacing.buttonRadius)
        }
        .bubblyTileLift()
    }
}

private struct OverviewInfoTile: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color
    var allowsMultilineValue: Bool = false
    var allowsTextSelection: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)

                Text(label.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .lineLimit(1)
            }

            valueText
        }
        .foregroundStyle(LColors.primaryText)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 18)
        }
        .bubblyTileLift()
    }

    @ViewBuilder
    private var valueText: some View {
        if allowsMultilineValue {
            let text = Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)

            if allowsTextSelection {
                text.textSelection(.enabled)
            } else {
                text
            }
        } else {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
    }
}

private struct LBadge: View {
    let text: String
    var color: Color = LColors.indicators

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(LColors.background)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.18))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.65), lineWidth: 1)
            )
    }
}

private struct TagPill: View {
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

private struct NotePreviewCard: View {
    let note: BookmarkNote

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(note.content)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.primaryText)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)

            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2.weight(.bold))
                .foregroundStyle(LColors.secondaryText)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .background(LColors.raisedSurfaces, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1.2)
        )
    }
}

private extension View {
    func bookmarkDetailCardBorder(_ color: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(color, lineWidth: 1.2)
        )
    }
}

// MARK: - Tab Enum

enum BookmarkDetailTab: String, CaseIterable, Identifiable {
    case notes
    case preview

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notes: return "Notes"
        case .preview: return "Preview"
        }
    }
}

private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
