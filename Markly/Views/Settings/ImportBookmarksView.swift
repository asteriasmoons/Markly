//
//  ImportBookmarksView.swift
//  Markly
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportBookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var folders: [BookmarkFolder]

    @State private var selectedFolder: BookmarkFolder?
    @State private var importedCount = 0
    @State private var skippedCount = 0
    @State private var statusMessage = "Select a file to begin importing."
    @State private var importError: String?

    @State private var showingFileImporter = false
    @State private var isImporting = false

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                headerSection

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        summaryCard
                        destinationCard
                        importCard
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
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [
                .json,
                .commaSeparatedText,
                .plainText
            ]
        ) { result in
            handleImport(result)
        }
    }
}

// MARK: - Sections

private extension ImportBookmarksView {

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Import")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)

                Text("Bring bookmarks into Markly.")
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

                sectionHeader(
                    title: "Import Status",
                    icon: "download",
                    accent: importAccent(at: 0)
                )

                HStack(spacing: 12) {
                    CountTile(
                        title: "Imported",
                        count: importedCount,
                        accent: importAccent(at: 0)
                    )

                    CountTile(
                        title: "Skipped",
                        count: skippedCount,
                        accent: importAccent(at: 1)
                    )
                }

                Text(statusMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                if let importError {
                    Text(importError)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.danger)
                }
            }
        }
        .importSectionAccent(importAccent(at: 0))
    }

    var destinationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {

                sectionHeader(
                    title: "Destination Folder",
                    icon: "blankfolder",
                    accent: importAccent(at: 1)
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {

                        Button {
                            selectedFolder = nil
                        } label: {
                            folderChip(
                                title: "Keep Original",
                                selected: selectedFolder == nil,
                                accent: importAccent(at: 1)
                            )
                        }

                        ForEach(Array(sortedFolders.enumerated()), id: \.offset) { index, folder in
                            Button {
                                selectedFolder = folder
                            } label: {
                                folderChip(
                                    title: folder.name,
                                    selected: selectedFolder?.persistentModelID == folder.persistentModelID,
                                    accent: importAccent(at: index + 2)
                                )
                            }
                        }
                    }
                }
            }
        }
        .importSectionAccent(importAccent(at: 1))
    }

    var importCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {

                sectionHeader(
                    title: "Import File",
                    icon: "share",
                    accent: importAccent(at: 2)
                )

                Text("Supports Markly JSON exports, CSV files, and Markdown exports.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Button {
                    showingFileImporter = true
                } label: {
                    Text(isImporting ? "Importing..." : "Choose File")
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
                .disabled(isImporting)
            }
        }
        .importSectionAccent(importAccent(at: 2))
    }

    func importAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    func sectionHeader(
        title: String,
        icon: String,
        accent: Color
    ) -> some View {
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

    func folderChip(
        title: String,
        selected: Bool,
        accent: Color
    ) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(selected ? LColors.primaryText : accent)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background {
                if selected {
                    BubblyTileSurface(tint: accent, cornerRadius: 999)
                } else {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                }
            }
            .overlay(
                Capsule()
                    .strokeBorder(
                        selected
                        ? AnyShapeStyle(accent)
                        : AnyShapeStyle(accent.opacity(0.28)),
                        lineWidth: 1
                    )
            )
            .bubblyTileLift(isEnabled: selected)
    }
}

// MARK: - Import Logic

private extension ImportBookmarksView {

    var sortedFolders: [BookmarkFolder] {
        folders.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func handleImport(
        _ result: Result<URL, Error>
    ) {
        importedCount = 0
        skippedCount = 0
        importError = nil

        guard case .success(let url) = result else {
            return
        }

        isImporting = true

        do {
            let access = url.startAccessingSecurityScopedResource()

            defer {
                if access {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)

            try importJSON(data)

            try modelContext.save()

            statusMessage = "Import completed successfully."
        } catch {
            importError = error.localizedDescription
            statusMessage = "Import failed."
        }

        isImporting = false
    }

    func importJSON(
        _ data: Data
    ) throws {

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let export = try decoder.decode(
            MarklyBookmarkExport.self,
            from: data
        )

        for item in export.bookmarks {

            let bookmark = BookmarkItem()

            bookmark.title = item.title
            bookmark.link = item.url
            bookmark.bookmarkDescription = item.bookmarkDescription
            bookmark.notes = item.notes
            bookmark.tags = item.tags
            bookmark.isFavorite = item.isFavorite
            bookmark.isArchived = item.isArchived

            if let selectedFolder {
                bookmark.folder = selectedFolder
            }

            modelContext.insert(bookmark)

            importedCount += 1
        }
    }
}

// MARK: - Supporting Views

private struct CountTile: View {
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    accent,
                    lineWidth: 1.2
                )
        )
    }
}

private extension View {
    func importSectionAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}

// MARK: - Import Models

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
}
