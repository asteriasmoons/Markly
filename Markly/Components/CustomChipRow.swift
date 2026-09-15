//
//  CustomChipRow.swift
//  Markly
//
//  Two reference-matched chip layouts:
//
//    WeekdayBubbleRow — S / M / T / W / T / F / S in seven rounded
//    squares. Multi-select. Solid accent fill when selected.
//
//    CustomChipRow — a row of rounded chips like "On time / 5 / 10 /
//    15 / 30 / 60". Single-select.
//
//  Both use solid colors from the theme. No gradients.
//

import SwiftUI

// MARK: - Weekday bubble row

struct WeekdayBubbleRow: View {
    @Environment(\.appTheme) private var theme

    /// Bitmask of selected weekdays, indexed 0=Sun … 6=Sat.
    @Binding var selection: Set<Int>

    private let labels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { day in
                bubble(day)
            }
        }
    }

    private func bubble(_ day: Int) -> some View {
        let isSelected = selection.contains(day)
        return Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
                if isSelected { selection.remove(day) } else { selection.insert(day) }
            }
        } label: {
            Text(labels[day])
                .font(theme.typography.bubble)
                .foregroundStyle(theme.palette.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected
                              ? theme.palette.primaryAction
                              : theme.palette.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? theme.palette.primaryAction
                                : theme.palette.raisedSurface,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Single-select chip row

struct CustomChipRow<Option: Hashable & Identifiable>: View {
    @Environment(\.appTheme) private var theme

    var options: [Option]
    var labelFor: (Option) -> String
    @Binding var selection: Option

    /// When true, the row scrolls horizontally instead of wrapping.
    var scrolls: Bool = true

    var body: some View {
        if scrolls {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { chip($0) }
                }
                .padding(.horizontal, 2)
            }
        } else {
            HStack(spacing: 8) {
                ForEach(options) { chip($0) }
            }
        }
    }

    @ViewBuilder
    private func chip(_ option: Option) -> some View {
        let isSelected = option == selection
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
                selection = option
            }
        } label: {
            Text(labelFor(option))
                .font(theme.typography.cardTitle)
                .foregroundStyle(theme.palette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected
                              ? theme.palette.primaryAction
                              : theme.palette.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? theme.palette.primaryAction
                                : theme.palette.raisedSurface,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
