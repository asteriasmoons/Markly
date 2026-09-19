//
//  ShareBookmarkView.swift
//  MarklyShare
//

import SwiftUI
import UIKit

struct ShareBookmarkView: View {
    @ObservedObject var viewModel: ShareBookmarkViewModel
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                MarklyBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        previewCard
                        formCard
                        errorMessageView
                    }
                    .padding(16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var previewCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Save to Markly")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Add this to your bookmark manager with the right details before it lands in your library.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))

                if !viewModel.url.isEmpty {
                    bookmarkPreviewRow
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bookmarkPreviewRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 46, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if let image = previewUIImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    Image(systemName: "link")
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title.isEmpty ? "Untitled Bookmark" : viewModel.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(viewModel.url)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    private var formCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("Title")
                textField("Enter title", text: $viewModel.title)

                fieldLabel("Description")
                textField("Add description", text: $viewModel.bookmarkDescription)

                fieldLabel("Link")
                textField("Paste or confirm link", text: $viewModel.url)

                fieldLabel("Tags")
                textField("Comma-separated tags", text: $viewModel.tagsRaw)

                fieldLabel("Folder")
                folderMenu
            }
        }
    }

    private var folderMenu: some View {
        let folders: [SharedFolderOption] = viewModel.availableFolders
        let selectedID = viewModel.selectedFolder.id

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(folders, id: \.id) { folder in
                Button {
                    viewModel.selectedFolder = folder
                } label: {
                    folderRow(
                        folder,
                        isSelected: folder.id == selectedID
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func folderRow(_ folder: SharedFolderOption, isSelected: Bool) -> some View {
        HStack {
            MarklyIconView(
                iconId: folder.iconName.isEmpty ? "folder.fill" : folder.iconName,
                size: 18
            )
            .foregroundStyle(.white)

            Text(folder.name)
                .foregroundStyle(.white)

            Spacer()

            if isSelected {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var errorMessageView: some View {
        if !viewModel.errorMessage.isEmpty {
            Text(viewModel.errorMessage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.red)
                .padding(.horizontal, 4)
        }
    }


    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
    }

    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        GlassTextField(
            placeholder: placeholder,
            text: text
        )
    }
    private var previewUIImage: UIImage? {
        if let data = viewModel.previewThumbnailData,
           let image = UIImage(data: data) {
            return image
        }

        if let data = viewModel.previewIconData,
           let image = UIImage(data: data) {
            return image
        }

        return nil
    }
}
