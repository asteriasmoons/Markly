//
//  CustomTabBar.swift
//  Markly
//
//  Custom bottom tab bar — the app never uses the system TabView chrome.
//  Icons come from the custom asset catalog only.
//

import SwiftUI

struct CustomTabItem: Identifiable, Hashable {
    let id: String
    let title: String
    let asset: String
}

struct CustomTabBar: View {
    @Environment(\.appTheme) private var theme

    var items: [CustomTabItem]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                let isSelected = item.id == selection
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                        selection = item.id
                    }
                } label: {
                    VStack(spacing: 4) {
                        CustomAssetIcon(
                            name: item.asset,
                            size: 22,
                            tint: isSelected
                                ? theme.palette.textPrimary
                                : theme.palette.textSecondary
                        )
                        Text(item.title)
                            .font(theme.typography.bubbleWeekday)
                            .foregroundStyle(isSelected
                                             ? theme.palette.textPrimary
                                             : theme.palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background {
            let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
            if #available(iOS 26.0, *) {
                shape.fill(.clear).glassEffect(.regular, in: shape)
            } else {
                shape.fill(theme.palette.raisedSurface)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5)
        }
        .padding(.horizontal, theme.metrics.pageHPadding)
    }
}
