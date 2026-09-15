//
//  SectionHeaderView.swift
//  Markly
//
//  The small "icon + heavy rounded title" section header used above
//  form groups in the reference (e.g. calendar-icon + "Schedule",
//  bell-icon + "Notifications & Alarm").
//

import SwiftUI

struct SectionHeaderView: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var iconAsset: String?
    var iconTint: Color? = nil

    var body: some View {
        HStack(spacing: theme.metrics.spacingS) {
            if let iconAsset {
                CustomAssetIcon(
                    name: iconAsset,
                    size: 22,
                    tint: iconTint ?? theme.palette.primaryAction
                )
            }
            Text(title)
                .font(theme.typography.sectionTitle)
                .foregroundStyle(theme.palette.textPrimary)
        }
    }
}

/// Small uppercase caption used above single controls (e.g. "DUE TIME").
struct FieldLabelView: View {
    @Environment(\.appTheme) private var theme
    var text: String
    var color: Color? = nil

    var body: some View {
        Text(text)
            .font(theme.typography.caption)
            .foregroundStyle(color ?? theme.palette.textSecondary)
            .textCase(.uppercase)
    }
}
