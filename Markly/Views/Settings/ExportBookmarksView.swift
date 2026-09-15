//
//  ExportBookmarksView.swift
//  Markly
//

import SwiftUI
import SwiftData

struct ExportBookmarksView: View {
    @Environment(\.dismiss) private var dismiss

    @Query private var bookmarks: [BookmarkItem]
    @Query private var folders: [BookmarkFolder]

    @State private var selectedFormat: ExportFormat = .json
    @State private var selectedScope: ExportScope = .all
    @State private var selectedFolder: BookmarkFolder?
    @State private var exportedFileURL: URL?
    @State private var statusMessage: String = "Choose what to export, then generate a file."
    @State private var exportError: String?

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                headerSection

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        summaryCard
                        formatCard
                        scopeCard
                        exportCard
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
    }
}

// MARK: - Sections

private extension ExportBookmarksView {
    var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Export")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)

                Text("Create a backup of your Markly library.")
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

    var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Library Snapshot", icon: "savesparkle", accent: exportAccent(at: 0))

                HStack(spacing: 12) {
                    ExportCountTile(title: "Bookmarks", count: filteredBookmarks.count, accent: exportAccent(at: 0))
                    ExportCountTile(title: "Folders", count: folders.count, accent: exportAccent(at: 1))
                }

                Text(statusMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let exportError {
                    Text(exportError)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .exportSectionAccent(exportAccent(at: 0))
    }

    var formatCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Format", icon: "docslove", accent: exportAccent(at: 1))

                VStack(spacing: 10) {
                    ForEach(Array(ExportFormat.allCases.enumerated()), id: \.offset) { index, format in
                        Button {
                            selectedFormat = format
                            exportedFileURL = nil
                            exportError = nil
                        } label: {
                            ExportOptionRow(
                                icon: format.icon,
                                title: format.title,
                                subtitle: format.subtitle,
                                isSelected: selectedFormat == format,
                                accent: exportAccent(at: index)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .exportSectionAccent(exportAccent(at: 1))
    }

    var scopeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Export Scope", icon: "blankfolder", accent: exportAccent(at: 2))

                VStack(spacing: 10) {
                    ForEach(Array(ExportScope.allCases.enumerated()), id: \.offset) { index, scope in
                        Button {
                            selectedScope = scope
                            exportedFileURL = nil
                            exportError = nil
                        } label: {
                            ExportOptionRow(
                                icon: scope.icon,
                                title: scope.title,
                                subtitle: scope.subtitle,
                                isSelected: selectedScope == scope,
                                accent: exportAccent(at: index)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if selectedScope == .folder {
                    folderPicker
                }
            }
        }
        .exportSectionAccent(exportAccent(at: 2))
    }

    var folderPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Folder")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(sortedFolders) { folder in
                        folderPickerButton(for: folder)
                    }
                }
            }
        }
    }

    func folderPickerButton(for folder: BookmarkFolder) -> some View {
        let isSelected = selectedFolder?.persistentModelID == folder.persistentModelID
        let iconId = folder.iconName.isEmpty ? "blankfolder" : folder.iconName
        let title = folder.name.isEmpty ? "Untitled Folder" : folder.name

        return Button {
            selectedFolder = folder
            exportedFileURL = nil
            exportError = nil
        } label: {
            HStack(spacing: 6) {
                MarklyIconView(
                    iconId: iconId,
                    size: 14
                )
                .foregroundStyle(isSelected ? AnyShapeStyle(LColors.indicators) : AnyShapeStyle(.white.opacity(0.75)))

                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? LColors.indicators.opacity(0.18) : Color.white.opacity(0.055))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? AnyShapeStyle(LColors.indicators) : AnyShapeStyle(Color.white.opacity(0.12)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    var exportCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Generate Export", icon: "share", accent: exportAccent(at: 3))

                Text("Markly will create a temporary file you can save to Files, send to another app, or keep as a backup.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    generateExport()
                } label: {
                    Text("Generate \(selectedFormat.title) Export")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background {
                            BubblyTileSurface(tint: LColors.indicators, cornerRadius: LSpacing.buttonRadius)
                        }
                        .bubblyTileLift()
                }
                .buttonStyle(.plain)

                if let exportedFileURL {
                    ShareLink(item: exportedFileURL) {
                        HStack(spacing: 10) {
                            Image("share")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(LColors.primaryText)

                            Text("Share Export File")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background {
                            BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: LSpacing.buttonRadius)
                        }
                        .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .exportSectionAccent(exportAccent(at: 3))
    }

    func exportAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    func sectionHeader(title: String, icon: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(accent)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(accent)
        }
    }
}

// MARK: - Export Logic

private extension ExportBookmarksView {
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

    var filteredBookmarks: [BookmarkItem] {
        let base = bookmarks.sorted {
            $0.createdAt > $1.createdAt
        }

        switch selectedScope {
        case .all:
            return base

        case .folder:
            guard let selectedFolder else { return [] }
            return base.filter {
                $0.folder?.persistentModelID == selectedFolder.persistentModelID
            }

        case .favorites:
            return base.filter { $0.isFavorite }

        case .archived:
            return base.filter { $0.isArchived }
        }
    }

    func generateExport() {
        exportError = nil
        exportedFileURL = nil

        guard !filteredBookmarks.isEmpty else {
            exportError = "There are no bookmarks to export for this selection."
            statusMessage = "Nothing was exported."
            return
        }

        if selectedScope == .folder && selectedFolder == nil {
            exportError = "Choose a folder before exporting."
            statusMessage = "Folder export needs a selected folder."
            return
        }

        do {
            let fileURL = try createExportFile()
            exportedFileURL = fileURL
            statusMessage = "Export created: \(fileURL.lastPathComponent)"
        } catch {
            exportError = error.localizedDescription
            statusMessage = "Export failed."
        }
    }

    func createExportFile() throws -> URL {
        let fileName = exportFileName()
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        switch selectedFormat {
        case .json:
            let export = MarklyBookmarkExport(
                appName: "Markly",
                exportedAt: Date(),
                scope: selectedScope.title,
                folderName: selectedFolder?.name,
                bookmarkCount: filteredBookmarks.count,
                bookmarks: filteredBookmarks.map { ExportedBookmark(bookmark: $0) }
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(export)
            try data.write(to: fileURL, options: .atomic)

        case .markdown:
            let text = markdownExport()
            try text.write(to: fileURL, atomically: true, encoding: .utf8)

        case .csv:
            let text = csvExport()
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        return fileURL
    }

    func exportFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"

        let stamp = formatter.string(from: Date())
        let scopeName = selectedScope.fileNameComponent
        return "markly-\(scopeName)-\(stamp).\(selectedFormat.fileExtension)"
    }

    func markdownExport() -> String {
        var lines: [String] = []

        lines.append("# Markly Bookmark Export")
        lines.append("")
        lines.append("- Exported: \(Date().formatted(date: .abbreviated, time: .shortened))")
        lines.append("- Scope: \(selectedScope.title)")
        lines.append("- Bookmarks: \(filteredBookmarks.count)")

        if let selectedFolder {
            lines.append("- Folder: \(selectedFolder.name)")
        }

        lines.append("")

        for bookmark in filteredBookmarks {
            lines.append("## \(safeText(bookmark.title, fallback: "Untitled Bookmark"))")
            lines.append("")
            lines.append("- URL: \(bookmark.url)")
            lines.append("- Folder: \(bookmark.folder?.name ?? "None")")
            lines.append("- Favorite: \(bookmark.isFavorite ? "Yes" : "No")")
            lines.append("- Archived: \(bookmark.isArchived ? "Yes" : "No")")
            lines.append("- Created: \(bookmark.createdAt.formatted(date: .abbreviated, time: .shortened))")
            lines.append("- Updated: \(bookmark.updatedAt.formatted(date: .abbreviated, time: .shortened))")

            if !bookmark.tags.isEmpty {
                lines.append("- Tags: \(bookmark.tags.joined(separator: ", "))")
            }

            if !bookmark.bookmarkDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("")
                lines.append(bookmark.bookmarkDescription)
            }

            if !bookmark.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("")
                lines.append("### Notes")
                lines.append(bookmark.notes)
            }

            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    func csvExport() -> String {
        var rows: [String] = []

        rows.append([
            "title",
            "url",
            "description",
            "notes",
            "folder",
            "tags",
            "favorite",
            "archived",
            "createdAt",
            "updatedAt"
        ].joined(separator: ","))

        for bookmark in filteredBookmarks {
            rows.append([
                csvEscape(safeText(bookmark.title, fallback: "Untitled Bookmark")),
                csvEscape(bookmark.url),
                csvEscape(bookmark.bookmarkDescription),
                csvEscape(bookmark.notes),
                csvEscape(bookmark.folder?.name ?? ""),
                csvEscape(bookmark.tags.joined(separator: "|")),
                csvEscape(bookmark.isFavorite ? "true" : "false"),
                csvEscape(bookmark.isArchived ? "true" : "false"),
                csvEscape(bookmark.createdAt.ISO8601Format()),
                csvEscape(bookmark.updatedAt.ISO8601Format())
            ].joined(separator: ","))
        }

        return rows.joined(separator: "\n")
    }

    func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    func safeText(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

// MARK: - Export Models

private struct MarklyBookmarkExport: Codable {
    let appName: String
    let exportedAt: Date
    let scope: String
    let folderName: String?
    let bookmarkCount: Int
    let bookmarks: [ExportedBookmark]
}

private struct ExportedBookmark: Codable {
    let title: String
    let url: String
    let bookmarkDescription: String
    let notes: String
    let folderName: String?
    let folderSystemKey: String?
    let tags: [String]
    let isFavorite: Bool
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date

    init(bookmark: BookmarkItem) {
        self.title = bookmark.title
        self.url = bookmark.url
        self.bookmarkDescription = bookmark.bookmarkDescription
        self.notes = bookmark.notes
        self.folderName = bookmark.folder?.name
        self.folderSystemKey = bookmark.folder?.systemKey
        self.tags = bookmark.tags
        self.isFavorite = bookmark.isFavorite
        self.isArchived = bookmark.isArchived
        self.createdAt = bookmark.createdAt
        self.updatedAt = bookmark.updatedAt
    }
}

// MARK: - Export Options

private enum ExportFormat: String, CaseIterable, Identifiable {
    case json
    case markdown
    case csv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .json: return "JSON"
        case .markdown: return "Markdown"
        case .csv: return "CSV"
        }
    }

    var subtitle: String {
        switch self {
        case .json:
            return "Best for restoring or importing data later."
        case .markdown:
            return "Best for readable personal backups."
        case .csv:
            return "Best for spreadsheets and tables."
        }
    }

    var icon: String {
        switch self {
        case .json: return "docslove"
        case .markdown: return "sticky"
        case .csv: return "books"
        }
    }

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .markdown: return "md"
        case .csv: return "csv"
        }
    }
}

private enum ExportScope: String, CaseIterable, Identifiable {
    case all
    case folder
    case favorites
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All Bookmarks"
        case .folder: return "Single Folder"
        case .favorites: return "Favorites"
        case .archived: return "Archived"
        }
    }

    var subtitle: String {
        switch self {
        case .all:
            return "Export your full bookmark library."
        case .folder:
            return "Export bookmarks from one folder."
        case .favorites:
            return "Export only starred bookmarks."
        case .archived:
            return "Export bookmarks you archived."
        }
    }

    var icon: String {
        switch self {
        case .all: return "savesparkle"
        case .folder: return "blankfolder"
        case .favorites: return "starmark"
        case .archived: return "archive"
        }
    }

    var fileNameComponent: String {
        switch self {
        case .all: return "all-bookmarks"
        case .folder: return "folder"
        case .favorites: return "favorites"
        case .archived: return "archived"
        }
    }
}

// MARK: - Supporting Views

private struct ExportOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            ExportIcon(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(accent)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isSelected {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(accent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.10) : Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isSelected ? AnyShapeStyle(accent) : AnyShapeStyle(accent.opacity(0.28)),
                    lineWidth: isSelected ? 1.4 : 1
                )
        )
    }
}

private struct ExportIcon: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            BubblyTileSurface(tint: accent, cornerRadius: 19)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(accent, lineWidth: 1.6)
                )

            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.primaryText)
        }
        .frame(width: 38, height: 38)
        .bubblyTileLift()
    }
}

private struct ExportCountTile: View {
    let title: String
    let count: Int
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(count)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}

private extension View {
    func exportSectionAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}
