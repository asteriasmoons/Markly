//
//  CustomTextField.swift
//  Markly
//
//  Themed wrapper around SwiftUI TextField so form controls all share
//  one look, use custom asset icons, and stay off system chrome.
//

import SwiftUI

struct CustomTextField: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var placeholder: String = ""
    var iconAsset: String? = nil
    var keyboard: UIKeyboardType = .default
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacingS) {
            Text(title)
                .font(theme.typography.caption)
                .foregroundStyle(theme.palette.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: theme.metrics.spacingS) {
                if let iconAsset {
                    CustomAssetIcon(name: iconAsset, size: 16,
                                    tint: theme.palette.textSecondary)
                }
                TextField(placeholder, text: $text)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.palette.textPrimary)
                    .keyboardType(keyboard)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, theme.metrics.spacingL)
            .padding(.vertical, theme.metrics.spacingM)
            .background {
                let shape = RoundedRectangle(cornerRadius: theme.metrics.cornerChip,
                                             style: .continuous)
                if #available(iOS 26.0, *) {
                    shape.fill(.clear).glassEffect(.regular, in: shape)
                } else {
                    shape.fill(theme.palette.surface)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: theme.metrics.cornerChip, style: .continuous)
                    .strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5)
            }
        }
    }
}
