//
//  AddEditDictionaryView.swift
//  Markly
//
//  Add / Edit form sheet for a dictionary (the container). Mirrors the
//  Add/Edit Folder sheet: a Dictionary Details section with an icon
//  preview and name field, a Choose Icon section, and Cancel/Save actions.
//

import SwiftUI
import SwiftData

struct AddEditDictionaryView: View {
    @Environment(\.modelContext) private var modelContext

    let dictionary: WordDictionary? // nil = create
    let onClose: () -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String = "openbook"

    var isEditing: Bool {
        dictionary != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MarklyBackground()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection
                        detailsSection
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
            if let dictionary {
                name = dictionary.name
                selectedIcon = dictionary.iconName.isEmpty ? "openbook" : dictionary.iconName
            } else {
                selectedIcon = "openbook"
            }
        }
    }
}

// MARK: - UI

private extension AddEditDictionaryView {
    var headerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(isEditing ? "Edit Dictionary" : "New Dictionary")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Group your words into a personal reference.")
                    .font(.subheadline)
                    .foregroundStyle(LColors.textSecondary)
            }

            Button(action: onClose) {
                CustomAssetIcon(name: "xmark", size: 30, tint: LColors.secondaryAccent)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dictionary Name")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(accent(at: 0))

            GlassTextField(
                placeholder: "Enter dictionary name",
                text: $name
            )
            .overlay(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .strokeBorder(accent(at: 0), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var iconLibrarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose Icon")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(accent(at: 1))

            selectedIconPreview

            IconPickerView(
                selectedIcon: $selectedIcon,
                iconBorderColor: LColors.secondaryAccent,
                iconBorderWidth: 1.5,
                glassDropdown: true
            )
                .frame(minHeight: 280)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var selectedIconPreview: some View {
        HStack(spacing: 12) {
            ZStack {
                BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: 23)
                    .clipShape(Circle())

                MarklyIconView(iconId: selectedIcon, size: 20)
                    .foregroundStyle(LColors.primaryText)
            }
            .frame(width: 46, height: 46)
            .overlay(
                Circle()
                    .strokeBorder(LColors.secondaryAccent, lineWidth: 1.5)
            )
            .bubblyTileLift()

            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Icon")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)

                Text("Pick the icon for this dictionary.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.secondaryText)
            }
        }
    }

    var actionsSection: some View {
        HStack {
            DictionarySectionActionButton(
                title: "Cancel",
                icon: "xmark",
                tint: LColors.secondaryAccent
            ) {
                onClose()
            }

            Spacer()

            DictionarySectionActionButton(
                title: isEditing ? "Save" : "Create",
                icon: "checkwavy",
                tint: LColors.primaryActions
            ) {
                save()
            }
            .opacity(canSave ? 1 : 0.45)
            .disabled(!canSave)
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func accent(at index: Int) -> Color {
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
            CustomAssetIcon(name: icon, size: 16, tint: accent)

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

    func iconBubble(iconId: String, accent: Color) -> some View {
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

// MARK: - Logic

private extension AddEditDictionaryView {
    func save() {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if let dictionary {
            dictionary.name = cleaned
            dictionary.iconName = selectedIcon
            dictionary.updatedAt = Date()
        } else {
            let new = WordDictionary(
                name: cleaned,
                iconName: selectedIcon,
                createdAt: Date(),
                updatedAt: Date()
            )
            modelContext.insert(new)
        }

        do {
            try modelContext.save()
            onClose()
        } catch {
            print("Failed to save dictionary: \(error)")
        }
    }
}

// MARK: - Supporting Views

private struct DictionarySectionActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                CustomAssetIcon(name: icon, size: 14, tint: LColors.primaryText)

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
    func sectionAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}
