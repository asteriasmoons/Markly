//
//  ReaderTextRenderer.swift
//  Markly
//

import SwiftUI

struct ReaderTextView: View {
    let text: ReaderText
    let textSize: ReaderTextSize
    var color: Color = LColors.textPrimary
    var weight: Font.Weight = .regular
    var isHeading: Bool = false
    var headingLevel: Int = 2

    var body: some View {
        Text(attributedText)
            .font(baseFont)
            .foregroundStyle(color)
            .lineSpacing(isHeading ? 2 : textSize.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var baseFont: Font {
        if isHeading {
            return .system(size: textSize.headingSize(for: headingLevel), weight: .black, design: .rounded)
        }

        return .system(size: textSize.bodySize, weight: weight, design: .rounded)
    }

    private var attributedText: AttributedString {
        var result = AttributedString()

        for run in text.runs {
            var segment = AttributedString(run.text)

            if isHeading {
                var font = Font.system(size: textSize.headingSize(for: headingLevel), weight: .black, design: .rounded)
                if run.isItalic {
                    font = font.italic()
                }
                segment.font = font
            } else if run.isCode {
                segment.font = .system(size: textSize.bodySize - 1, weight: .semibold, design: .monospaced)
                segment.backgroundColor = UIColor(LColors.raisedSurfaces)
                segment.foregroundColor = UIColor(LColors.indicators)
            } else {
                let runWeight: Font.Weight = run.isBold ? .black : weight
                var font = Font.system(size: textSize.bodySize, weight: runWeight, design: .rounded)
                if run.isItalic {
                    font = font.italic()
                }
                segment.font = font
            }

            if let linkURL = run.linkURL {
                segment.link = linkURL
                segment.foregroundColor = UIColor(LColors.primaryActions)
            }

            result += segment
        }

        return result
    }
}
