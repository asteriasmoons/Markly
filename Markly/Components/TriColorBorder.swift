//
//  TriColorBorder.swift
//  Markly
//

import SwiftUI

struct TriColorBorder<BorderShape: InsettableShape>: View {
    let shape: BorderShape
    var lineWidth: CGFloat = 1.2

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = proxy.size.width / 3

            ZStack(alignment: .leading) {
                borderSegment(
                    color: LColors.primaryActions,
                    width: segmentWidth,
                    offset: 0
                )

                borderSegment(
                    color: LColors.secondaryAccent,
                    width: segmentWidth,
                    offset: segmentWidth
                )

                borderSegment(
                    color: LColors.indicators,
                    width: segmentWidth,
                    offset: segmentWidth * 2
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func borderSegment(
        color: Color,
        width: CGFloat,
        offset: CGFloat
    ) -> some View {
        shape
            .strokeBorder(color, lineWidth: lineWidth)
            .mask(alignment: .leading) {
                Rectangle()
                    .frame(width: width)
                    .offset(x: offset)
            }
    }
}

extension View {
    func triColorBorder<S: InsettableShape>(
        _ shape: S,
        lineWidth: CGFloat = 1.2
    ) -> some View {
        overlay {
            TriColorBorder(shape: shape, lineWidth: lineWidth)
        }
    }
}
