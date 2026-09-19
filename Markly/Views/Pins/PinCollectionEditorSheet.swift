//
//  PinCollectionEditorSheet.swift
//  Markly
//

import SwiftUI

struct PinCollectionEditorSheet: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    @Binding var collectionName: String
    @Binding var selectedIcon: String
    let onClose: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    collectionEditorSection(title: "Collection Name", accent: collectionEditorAccent(at: 0)) {
                        GlassTextField(
                            placeholder: "Collection name",
                            text: $collectionName,
                            borderColor: collectionEditorAccent(at: 0),
                            borderLineWidth: 1.2
                        )
                    }

                    collectionEditorSection(title: "Choose Icon", accent: collectionEditorAccent(at: 1)) {
                        selectedIconPreview

                        IconPickerView(
                            selectedIcon: $selectedIcon,
                            iconBorderColor: LColors.secondaryAccent,
                            iconBorderWidth: 1.5,
                            glassDropdown: true
                        )
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 420)
                    }

                    saveButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 22)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private extension PinCollectionEditorSheet {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 14) {
                Text(title)
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

            Text(subtitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
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

                Text("Pick the icon for this collection.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.secondaryText)
            }
        }
    }

    var saveButton: some View {
        Button(action: onSave) {
            Text(actionTitle)
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
    }

    func collectionEditorSection<Content: View>(
        title: String,
        accent: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func collectionEditorAccent(at index: Int) -> Color {
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
