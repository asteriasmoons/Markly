//
//  BookmarkCard.swift
//  Markly
//

import SwiftUI
import SwiftData
import UIKit

struct BookmarkCard: View {
    let bookmark: BookmarkItem
    let folderName: String
    let onToggleFavorite: () -> Void
    let onOpen: () -> Void
    let onMoveToFolder: (BookmarkFolder) -> Void
    let onDelete: () -> Void
    let availableFolders: [BookmarkFolder]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                topRow
                middleContent
                bottomRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: LSpacing.cardRadius))
        .onTapGesture {
            onOpen()
        }
    }
}

// MARK: - Local Supporting Views

private struct LiquidBookmarkChip: View {
    let text: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)

            Text(text)
                .font(.caption2.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundStyle(LColors.primaryText)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 999)
        }
        .bubblyTileLift()
    }
}

// MARK: - UI

private extension BookmarkCard {
    var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            previewImage

            VStack(alignment: .leading, spacing: 6) {
                Text(bookmark.title.isEmpty ? "Untitled Bookmark" : bookmark.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    if !folderName.isEmpty {
                        LiquidBookmarkChip(
                            text: folderName,
                            icon: "openfolder",
                            tint: LColors.primaryActions
                        )
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                onToggleFavorite()
            } label: {
                Image("starfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(bookmark.isFavorite ? LColors.indicators : LColors.textSecondary.opacity(0.62))
                    .frame(width: 34, height: 34)
                    .background(
                        bookmark.isFavorite ? LColors.indicators.opacity(0.18) : Color.white.opacity(0.06),
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .stroke(bookmark.isFavorite ? LColors.indicators.opacity(0.72) : LColors.glassBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onTapGesture { }
        }
    }

    var previewImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(LColors.glassBorder, lineWidth: 1)
                )
                .frame(width: 46, height: 46)

            if let image = bookmarkPreviewUIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Image("linkcircle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    var bookmarkPreviewUIImage: UIImage? {
        if let thumbnailData = bookmark.thumbnailData,
           let image = UIImage(data: thumbnailData) {
            return image
        }

        if let iconData = bookmark.iconData,
           let image = UIImage(data: iconData) {
            return image
        }

        return nil
    }

    var middleContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !bookmark.bookmarkDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(bookmark.bookmarkDescription)
                    .font(.subheadline)
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !bookmark.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bookmark.tags, id: \.self) { tag in
                            LiquidBookmarkChip(
                                text: tag,
                                icon: "tagsparkle",
                                tint: LColors.secondaryAccent
                            )
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
            }

            if !bookmark.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))

                    Text(bookmark.notes)
                        .font(.footnote)
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    var bottomRow: some View {
        HStack(spacing: 10) {
            if !bookmark.link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                LiquidBookmarkChip(
                    text: bookmark.link.trimmingCharacters(in: .whitespacesAndNewlines),
                    icon: "link",
                    tint: LColors.indicators
                )
            }

            Spacer(minLength: 0)

            moveMenu

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image("trashfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.06), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(LColors.glassBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    var moveMenu: some View {
        Menu {
            ForEach(availableFolders) { folder in
                Button(folder.name.isEmpty ? "Untitled" : folder.name) {
                    onMoveToFolder(folder)
                }
            }
        } label: {
            Image("openfolder")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.06), in: Circle())
                .overlay(
                    Circle()
                        .stroke(LColors.glassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
