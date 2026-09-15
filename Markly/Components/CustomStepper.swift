//
//  CustomStepper.swift
//  Markly
//
//  Reference-matched stepper row: title + tiny caption on the left,
//  circular minus button, the current number, circular plus button on
//  the right. All custom — no system Stepper.
//

import SwiftUI

struct CustomStepperRow: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var unitLabel: String?
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...9999
    var step: Int = 1

    var body: some View {
        GlassCard(emphasis: .regular) {
            HStack(spacing: theme.metrics.spacingM) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.cardTitle)
                        .foregroundStyle(theme.palette.textPrimary)
                    if let unitLabel {
                        Text(unitLabel)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                }
                Spacer(minLength: 0)

                stepButton(asset: "minuswavy") {
                    let next = value - step
                    if range.contains(next) { value = next }
                }

                Text(String(value))
                    .font(theme.typography.amount)
                    .foregroundStyle(theme.palette.textPrimary)
                    .frame(minWidth: 40)
                    .contentTransition(.numericText())

                stepButton(asset: "addwavy") {
                    let next = value + step
                    if range.contains(next) { value = next }
                }
            }
        }
    }

    private func stepButton(asset: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            CustomAssetIcon(
                name: asset,
                size: 16,
                tint: theme.palette.textPrimary
            )
            .padding(10)
            .background {
                Circle().fill(theme.palette.raisedSurface)
            }
            .overlay {
                Circle().strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}
