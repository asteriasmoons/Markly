//
//  CustomButton.swift
//  Markly
//
//  Custom action buttons — used in place of toolbar items, `.cancelButton`,
//  and `EditButton`. All rendering uses the app's theme + Liquid Glass.
//

import SwiftUI

enum CustomButtonStyle {
    case primary
    case secondary
    case ghost
    case danger
}

struct CustomButton: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var iconAsset: String? = nil
    var style: CustomButtonStyle = .primary
    var fullWidth: Bool = false
    var usesBubblySurface: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.metrics.spacingS) {
                if let iconAsset {
                    CustomAssetIcon(name: iconAsset, size: 16, tint: foreground)
                }
                Text(title)
                    .font(theme.typography.cardTitle)
                    .foregroundStyle(foreground)
            }
            .padding(.horizontal, theme.metrics.spacingL)
            .padding(.vertical, theme.metrics.spacingM)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background {
                if usesBubblySurface {
                    BubblyTileSurface(tint: bubblyTint,
                                      cornerRadius: theme.metrics.cornerButton)
                } else {
                    background
                }
            }
            .overlay {
                if !usesBubblySurface {
                    RoundedRectangle(cornerRadius: theme.metrics.cornerButton, style: .continuous)
                        .strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5)
                }
            }
            .bubblyTileLift(isEnabled: usesBubblySurface)
            .compositingGroup()
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch style {
        case .primary: return theme.palette.textPrimary
        case .secondary: return theme.palette.textPrimary
        case .ghost: return theme.palette.textSecondary
        case .danger: return theme.palette.textPrimary
        }
    }

    private var bubblyTint: Color {
        switch style {
        case .primary: return theme.palette.primaryAction
        case .danger: return theme.palette.secondaryAccent
        case .secondary, .ghost: return theme.palette.raisedSurface
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.cornerButton, style: .continuous)
        if #available(iOS 26.0, *) {
            switch style {
            case .primary:
                shape.fill(.clear)
                    .glassEffect(.regular.tint(theme.palette.primaryAction).interactive(),
                                 in: shape)
            case .secondary:
                shape.fill(.clear)
                    .glassEffect(.regular.interactive(), in: shape)
            case .ghost:
                shape.fill(.clear)
            case .danger:
                shape.fill(.clear)
                    .glassEffect(.regular.tint(theme.palette.secondaryAccent).interactive(),
                                 in: shape)
            }
        } else {
            switch style {
            case .primary:   shape.fill(theme.palette.primaryAction)
            case .secondary: shape.fill(theme.palette.raisedSurface)
            case .ghost:     shape.fill(Color.clear)
            case .danger:    shape.fill(theme.palette.secondaryAccent)
            }
        }
    }
}

/// Small icon-only button. Used for row-level actions.
struct CustomIconButton: View {
    @Environment(\.appTheme) private var theme
    var asset: String
    var size: CGFloat = 18
    var tint: Color? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            CustomAssetIcon(name: asset, size: size, tint: tint ?? theme.palette.textPrimary)
                .padding(9)
                .background {
                    if #available(iOS 26.0, *) {
                        Circle().fill(.clear)
                            .glassEffect(.regular.interactive(), in: Circle())
                    } else {
                        Circle().fill(theme.palette.surface)
                    }
                }
                .overlay { Circle().strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5) }
        }
        .buttonStyle(.plain)
    }
}
