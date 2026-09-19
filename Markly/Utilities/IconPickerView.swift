//
//  IconPickerView.swift
//  Markly
//

import SwiftUI

// MARK: - Icon Picker Sheet

struct IconPickerView: View {
    @Binding var selectedIcon: String

    var iconBorderColor: Color? = nil
    var iconBorderWidth: CGFloat? = nil
    var glassDropdown: Bool = false
    var dropdownTint: Color? = nil

    @State private var selectedCategoryName: String = IconLibrary.pickerCategories.first?.name ?? ""
    @State private var isCategoryDropdownOpen = false

    private let maxVisibleCategoryRows = 5
    private let categoryRowHeight: CGFloat = 46

    private var selectedCategory: IconCategory {
        IconLibrary.pickerCategories.first { $0.name == selectedCategoryName }
        ?? IconLibrary.pickerCategories.first
        ?? IconCategory(name: "Icons", icons: [])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryDropdown

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                    spacing: 10
                ) {
                    ForEach(selectedCategory.icons) { icon in
                        Button {
                            selectedIcon = icon.id
                        } label: {
                            iconCell(icon)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .onAppear(perform: selectCategoryContainingSelectedIcon)
        .onChange(of: selectedIcon) { _, _ in
            selectCategoryContainingSelectedIconIfNeeded()
        }
        .background(Color.clear)
    }

    private var categoryDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                    isCategoryDropdownOpen.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selectedCategory.name)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.primaryText)
                        .lineLimit(1)

                    Spacer()

                    Image("chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LColors.secondaryText)
                        .rotationEffect(.degrees(isCategoryDropdownOpen ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    if glassDropdown {
                        BubblyTileSurface(tint: dropdownTint ?? LColors.secondaryAccent, cornerRadius: LSpacing.inputRadius)
                    } else {
                        RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                            .fill(LColors.raisedSurfaces)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                        .strokeBorder(glassDropdown ? (dropdownTint ?? LColors.secondaryAccent) : LColors.glassBorder, lineWidth: glassDropdown ? 1.2 : 1)
                )
                .bubblyTileLift(isEnabled: glassDropdown)
            }
            .buttonStyle(.plain)

            if isCategoryDropdownOpen {
                ScrollView(.vertical, showsIndicators: IconLibrary.pickerCategories.count > maxVisibleCategoryRows) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(IconLibrary.pickerCategories, id: \.name) { category in
                            Button {
                                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                                    selectedCategoryName = category.name
                                    isCategoryDropdownOpen = false
                                }
                            } label: {
                                HStack {
                                    Text(category.name)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.primaryText)

                                    Spacer()

                                    if selectedCategoryName == category.name {
                                        Image("checkwavy")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                            .foregroundStyle(glassDropdown ? LColors.primaryText : LColors.indicators)
                                    }
                                }
                                .frame(height: categoryRowHeight)
                                .padding(.horizontal, 12)
                                .background(
                                    selectedCategoryName == category.name
                                        ? (glassDropdown ? Color.white.opacity(0.08) : LColors.indicators.opacity(0.20))
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
                .frame(
                    maxHeight: CGFloat(min(maxVisibleCategoryRows, IconLibrary.pickerCategories.count)) * categoryRowHeight + 16
                )
                .background {
                    if glassDropdown {
                        BubblyTileSurface(tint: dropdownTint ?? LColors.secondaryAccent, cornerRadius: 16)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LColors.surfaces)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(glassDropdown ? (dropdownTint ?? LColors.secondaryAccent) : LColors.glassBorder, lineWidth: glassDropdown ? 1.2 : 1)
                )
                .bubblyTileLift(isEnabled: glassDropdown)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func iconCell(_ icon: MarklyIcon) -> some View {
        let isSelected = selectedIcon == icon.id
        return Group {
            Image(icon.id)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(isSelected ? LColors.indicators : LColors.textPrimary)
        }
        .frame(width: 48, height: 48)
        .background(
            isSelected ? LColors.glassSurface2 : LColors.glassSurface,
            in: RoundedRectangle(cornerRadius: LSpacing.inputRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: LSpacing.inputRadius)
                .strokeBorder(
                    iconBorderColor ?? (isSelected ? LColors.glassBorderStrong : LColors.glassBorder),
                    lineWidth: iconBorderWidth ?? (isSelected ? 1.5 : 1)
                )
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }

    private func selectCategoryContainingSelectedIcon() {
        if let category = IconLibrary.pickerCategories.first(where: { category in
            category.icons.contains { $0.id == selectedIcon }
        }) {
            selectedCategoryName = category.name
        } else if selectedCategoryName.isEmpty {
            selectedCategoryName = IconLibrary.pickerCategories.first?.name ?? ""
        }
    }

    private func selectCategoryContainingSelectedIconIfNeeded() {
        guard !selectedCategory.icons.contains(where: { $0.id == selectedIcon }) else { return }
        selectCategoryContainingSelectedIcon()
    }
}

// MARK: - Inline Icon Renderer

struct MarklyIconView: View {
    let iconId: String
    var size: CGFloat = 22

    private var icon: MarklyIcon {
        IconLibrary.all.first { $0.id == iconId } ?? MarklyIcon(iconId, custom: true)
    }

    var body: some View {
        Image(icon.id)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
