//
//  AddEditBookmarkFolderView.swift
//  Markly
//

import SwiftUI
import SwiftData

struct AddEditBookmarkFolderView: View {
    @Environment(\.modelContext) private var modelContext

    let folder: BookmarkFolder? // nil = create
    let onClose: () -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"

    var isEditing: Bool {
        folder != nil
    }

    var isInbox: Bool {
        folder?.systemKey == "inbox"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MarklyBackground()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection
                        folderDetailsSection
                        iconLibrarySection
                        actionsSection
                    }
                    .padding(22)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if let folder {
                name = folder.name
                selectedIcon = folder.iconName.isEmpty ? "folder" : folder.iconName
            } else {
                selectedIcon = "folder"
            }
        }
    }
}

// MARK: - UI

private extension AddEditBookmarkFolderView {
    var headerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(isEditing ? "Edit Folder" : "New Folder")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Organize your saved links into intentional spaces.")
                    .font(.subheadline)
                    .foregroundStyle(LColors.textSecondary)
            }

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var folderDetailsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                folderSheetSectionHeader(
                    title: "Folder Details",
                    icon: "blankfolder",
                    accent: folderSheetAccent(at: 0)
                )

                HStack(spacing: 12) {
                    FolderSheetIconBubble(iconId: selectedIcon, accent: folderSheetAccent(at: 0))

                    VStack(alignment: .leading, spacing: 4) {
                        label("Folder Icon", accent: folderSheetAccent(at: 0))

                        Text("Pick an icon for this folder.")
                            .font(.footnote)
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                label("Folder Name", accent: folderSheetAccent(at: 0))

                GlassTextField(
                    placeholder: "Enter folder name",
                    text: $name
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                        .strokeBorder(folderSheetAccent(at: 0), lineWidth: 1)
                )

                if isInbox {
                    Text("The Inbox folder cannot be renamed.")
                        .font(.footnote)
                        .foregroundStyle(LColors.warning)
                }
            }
        }
        .folderSheetSectionAccent(folderSheetAccent(at: 0))
    }

    var iconLibrarySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                folderSheetSectionHeader(
                    title: "Choose Icon",
                    icon: "graphicdesign",
                    accent: folderSheetAccent(at: 1)
                )

                IconPickerView(selectedIcon: $selectedIcon)
                    .frame(minHeight: 280)
            }
        }
        .folderSheetSectionAccent(folderSheetAccent(at: 1))
    }

    var actionsSection: some View {
        HStack {
            FolderSheetActionButton(
                title: "Cancel",
                icon: "xmark",
                tint: LColors.secondaryAccent
            ) {
                onClose()
            }

            Spacer()

            FolderSheetActionButton(
                title: isEditing ? "Save" : "Create",
                icon: "checkwavy",
                tint: LColors.primaryActions
            ) {
                save()
            }
            .opacity(isInbox ? 0.5 : 1)
            .disabled(isInbox)
        }
    }

    func folderSheetAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    func folderSheetSectionHeader(title: String, icon: String, accent: Color) -> some View {
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

    func label(_ text: String, accent: Color) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(accent)
    }
}

// MARK: - Supporting Views

private struct FolderSheetIconBubble: View {
    let iconId: String
    let accent: Color

    var body: some View {
        ZStack {
            BubblyTileSurface(tint: accent, cornerRadius: 23)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(accent, lineWidth: 1.6)
                )

            MarklyIconView(iconId: iconId, size: 22)
                .foregroundStyle(LColors.primaryText)
        }
        .frame(width: 46, height: 46)
        .bubblyTileLift()
    }
}

private struct FolderSheetActionButton: View {
    let title: String
    let icon: String
    let tint: Color
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
                BubblyTileSurface(tint: tint, cornerRadius: LSpacing.buttonRadius)
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func folderSheetSectionAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}

// MARK: - Logic

private extension AddEditBookmarkFolderView {
    func save() {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if let folder {
            guard folder.systemKey != "inbox" else { return }

            folder.name = cleaned
            folder.iconName = selectedIcon
            folder.updatedAt = Date()
        } else {

            let new = BookmarkFolder(
                name: cleaned,
                systemKey: "",
                iconName: selectedIcon,
                createdAt: Date(),
                updatedAt: Date()
            )
            modelContext.insert(new)
        }

        do {
            try modelContext.save()
            SharedFolderExportManager.exportFolders(modelContext: modelContext)
            onClose()
        } catch {
            print("Failed to save folder: \(error)")
        }
    }

}
