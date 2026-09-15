//
//  CustomSegmented.swift
//  Markly
//
//  Custom segmented control — used for compact filter rows. Never uses
//  the system Picker(.segmented) style.
//

import SwiftUI

struct CustomSegmented<Option: Hashable & Identifiable>: View {
    @Environment(\.appTheme) private var theme

    var options: [Option]
    var labelFor: (Option) -> String
    @Binding var selection: Option
    var usesBubblySurface: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        selection = option
                    }
                } label: {
                    Text(labelFor(option))
                        .font(theme.typography.caption)
                        .foregroundStyle(isSelected
                                         ? theme.palette.textPrimary
                                         : theme.palette.textSecondary)
                        .padding(.horizontal, theme.metrics.spacingM)
                        .padding(.vertical, 8)
                        .background {
                            if usesBubblySurface {
                                BubblyTileSurface(
                                    tint: isSelected
                                        ? theme.palette.primaryAction
                                        : theme.palette.raisedSurface,
                                    cornerRadius: theme.metrics.cornerChip
                                )
                            } else {
                                let shape = Capsule(style: .continuous)
                                if isSelected {
                                    if #available(iOS 26.0, *) {
                                        shape.fill(.clear)
                                            .glassEffect(
                                                .regular.tint(theme.palette.primaryAction)
                                                        .interactive(),
                                                in: shape)
                                    } else {
                                        shape.fill(theme.palette.primaryAction)
                                    }
                                } else {
                                    Color.clear
                                }
                            }
                        }
                        .bubblyTileLift(isEnabled: usesBubblySurface)
                        .compositingGroup()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            if usesBubblySurface {
                Color.clear
            } else {
                let shape = Capsule(style: .continuous)
                if #available(iOS 26.0, *) {
                    shape.fill(.clear).glassEffect(.regular, in: shape)
                } else {
                    shape.fill(theme.palette.surface)
                }
            }
        }
        .overlay {
            if !usesBubblySurface {
                Capsule().strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5)
            }
        }
    }
}
