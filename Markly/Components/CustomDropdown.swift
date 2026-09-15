//
//  CustomDropdown.swift
//  Markly
//
//  Custom dropdown menu — the app never uses the system Menu or Picker.
//  Renders selected value in a Liquid Glass chip and opens an inline
//  drum-style list of options.
//

import SwiftUI

struct CustomDropdown<Option: Hashable & Identifiable>: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var options: [Option]
    var labelFor: (Option) -> String
    var iconFor: ((Option) -> String?)? = nil
    var accent: Color? = nil
    var maxVisibleRows: Int? = nil
    var showsDividers: Bool = true
    @Binding var selection: Option?

    @State private var isOpen = false

    private var rowHeight: CGFloat {
        44
    }

    private var dropdownHeight: CGFloat? {
        guard let maxVisibleRows else { return nil }
        return CGFloat(min(options.count, maxVisibleRows)) * rowHeight
    }

    private var activeAccent: Color {
        accent ?? theme.palette.primaryAction
    }

    @ViewBuilder
    private var dropdownRows: some View {
        VStack(spacing: 0) {
            ForEach(options) { option in
                Button {
                    selection = option
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        isOpen = false
                    }
                } label: {
                    HStack(spacing: theme.metrics.spacingS) {
                        if let assetName = iconFor?(option) {
                            CustomAssetIcon(name: assetName, size: 15,
                                            tint: theme.palette.textPrimary)
                        }
                        Text(labelFor(option))
                            .font(theme.typography.body)
                            .foregroundStyle(theme.palette.textPrimary)
                        Spacer(minLength: 0)
                        if selection == option {
                            CustomAssetIcon(name: "circlemarked", size: 14,
                                            tint: activeAccent)
                        }
                    }
                    .padding(.horizontal, theme.metrics.spacingL)
                    .frame(height: rowHeight)
                }
                .buttonStyle(.plain)
                if showsDividers, option != options.last {
                    Rectangle()
                        .fill(theme.palette.raisedSurface)
                        .frame(height: 0.5)
                        .padding(.horizontal, theme.metrics.spacingL)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacingS) {
            Text(title)
                .font(theme.typography.caption)
                .foregroundStyle(accent ?? theme.palette.textSecondary)
                .textCase(.uppercase)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isOpen.toggle()
                }
            } label: {
                HStack(spacing: theme.metrics.spacingS) {
                    if let selection, let assetName = iconFor?(selection) {
                        CustomAssetIcon(name: assetName, size: 16, tint: theme.palette.textPrimary)
                    }
                    Text(selection.map(labelFor) ?? "Select…")
                        .font(theme.typography.body)
                        .foregroundStyle(selection == nil
                                         ? theme.palette.textSecondary
                                         : theme.palette.textPrimary)
                    Spacer(minLength: 0)
                    CustomAssetIcon(
                        name: isOpen ? "chevup" : "chevdown",
                        size: 14,
                        tint: theme.palette.textSecondary
                    )
                }
                .padding(.horizontal, theme.metrics.spacingL)
                .padding(.vertical, theme.metrics.spacingM)
                .background {
                    let shape = RoundedRectangle(cornerRadius: theme.metrics.cornerChip,
                                                 style: .continuous)
                    if let accent {
                        BubblyTileSurface(tint: accent, cornerRadius: theme.metrics.cornerChip)
                    } else if #available(iOS 26.0, *) {
                        shape.fill(.clear)
                            .glassEffect(.regular.interactive(), in: shape)
                    } else {
                        shape.fill(theme.palette.raisedSurface)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: theme.metrics.cornerChip, style: .continuous)
                        .strokeBorder(accent ?? theme.palette.raisedSurface, lineWidth: accent == nil ? 0.5 : 1.2)
                }
                .bubblyTileLift(isEnabled: accent != nil)
            }
            .buttonStyle(.plain)

            if isOpen {
                Group {
                    if let dropdownHeight {
                        ScrollView(.vertical, showsIndicators: options.count > (maxVisibleRows ?? options.count)) {
                            dropdownRows
                        }
                        .frame(height: dropdownHeight)
                    } else {
                        dropdownRows
                    }
                }
                .background {
                    let shape = RoundedRectangle(cornerRadius: theme.metrics.cornerChip,
                                                 style: .continuous)
                    if let accent {
                        BubblyTileSurface(tint: accent, cornerRadius: theme.metrics.cornerChip)
                    } else if #available(iOS 26.0, *) {
                        shape.fill(.clear)
                            .glassEffect(.regular, in: shape)
                    } else {
                        shape.fill(theme.palette.surface)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: theme.metrics.cornerChip, style: .continuous)
                        .strokeBorder(accent ?? theme.palette.raisedSurface, lineWidth: accent == nil ? 0.5 : 1.2)
                }
                .bubblyTileLift(isEnabled: accent != nil)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
    }
}
