//
//  CustomToggle.swift
//  Markly
//
//  Matches the Lurelia reference toggle. The thumb is a full Circle
//  whose diameter and inset are chosen so it sits flush inside the
//  Capsule track in BOTH the ON and OFF positions. Track fills the
//  approved surface color; thumb fills primaryAction when ON and
//  raisedSurface when OFF; the border swaps between primaryAction
//  and raisedSurface. No opacity variants, no gradients.
//

import SwiftUI

// MARK: - Bare toggle

struct CustomToggle: View {
    @Environment(\.appTheme) private var theme
    @Binding var isOn: Bool
    /// Custom asset drawn inside the thumb circle.
    var thumbAsset: String? = nil
    /// Optional label to the left of the switch.
    var label: String? = nil

    // Chosen so thumbSize + 2·thumbInset == pillHeight exactly.
    private let pillWidth: CGFloat = 60
    private let pillHeight: CGFloat = 36
    private let thumbInset: CGFloat = 4
    private var thumbSize: CGFloat { pillHeight - (thumbInset * 2) }  // 28

    var body: some View {
        HStack(spacing: theme.metrics.spacingM) {
            if let label {
                Text(label)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.palette.textPrimary)
                Spacer(minLength: 0)
            }
            switchPill
        }
    }

    private var switchPill: some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule(style: .continuous)
                    .fill(theme.palette.surface)
                    .frame(width: pillWidth, height: pillHeight)
                    .overlay {
                        Capsule(style: .continuous).strokeBorder(
                            isOn ? theme.palette.primaryAction
                                 : theme.palette.raisedSurface,
                            lineWidth: 1
                        )
                    }

                thumb
                    .padding(thumbInset)
            }
            .frame(width: pillWidth, height: pillHeight)
        }
        .buttonStyle(.plain)
    }

    private var thumb: some View {
        Circle()
            .fill(isOn ? theme.palette.primaryAction : theme.palette.raisedSurface)
            .frame(width: thumbSize, height: thumbSize)
            .overlay {
                if let thumbAsset {
                    CustomAssetIcon(
                        name: thumbAsset,
                        size: 14,
                        tint: isOn ? theme.palette.textPrimary
                                   : theme.palette.textSecondary
                    )
                }
            }
    }
}

// MARK: - Row form (title + subtitle + toggle on the right)

/// The card-row toggle from the reference: bold title, muted subtitle,
/// pill toggle with an icon in its thumb, all inside a GlassCard.
struct CustomToggleRow: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var subtitle: String? = nil
    var thumbAsset: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        GlassCard(emphasis: .regular) {
            HStack(alignment: .center, spacing: theme.metrics.spacingM) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.cardTitle)
                        .foregroundStyle(theme.palette.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                CustomToggle(isOn: $isOn, thumbAsset: thumbAsset)
            }
        }
    }
}
