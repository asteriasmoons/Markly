//
//  ReaderBlockView.swift
//  Markly
//

import SwiftUI

struct ReaderBlockView: View {
    let block: ReaderBlock
    let textSize: ReaderTextSize

    var body: some View {
        switch block {
        case .heading(let level, let content):
            ReaderTextView(
                text: content,
                textSize: textSize,
                weight: .black,
                isHeading: true,
                headingLevel: level
            )
            .padding(.top, headingTopPadding(for: level))
            .padding(.bottom, 2)
            .accessibilityAddTraits(.isHeader)

        case .paragraph(let content):
            ReaderTextView(text: content, textSize: textSize)
                .padding(.vertical, 4)

        case .image(let url, let alt, let caption):
            ReaderImageBlock(url: url, alt: alt, caption: caption)
                .padding(.vertical, 8)

        case .quote(let content):
            GlassCard(padding: 14) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(LColors.secondaryAccent)
                        .frame(width: 4)

                    ReaderTextView(
                        text: content,
                        textSize: textSize,
                        color: LColors.primaryText,
                        weight: .semibold
                    )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous)
                    .strokeBorder(LColors.secondaryAccent, lineWidth: 1)
            )
            .padding(.vertical, 8)

        case .unorderedList(let items):
            ReaderListView(items: items, ordered: false, textSize: textSize)
                .padding(.vertical, 4)

        case .orderedList(let items):
            ReaderListView(items: items, ordered: true, textSize: textSize)
                .padding(.vertical, 4)

        case .code(let language, let code):
            ReaderCodeBlock(language: language, code: code, textSize: textSize)
                .padding(.vertical, 8)

        case .divider:
            Rectangle()
                .fill(LColors.raisedSurfaces)
                .frame(height: 1)
                .padding(.vertical, 14)

        case .link(let text, let url):
            Link(destination: url) {
                HStack(spacing: 10) {
                    Image("link")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LColors.primaryText)

                    ReaderTextView(
                        text: text,
                        textSize: textSize,
                        color: LColors.primaryText,
                        weight: .black
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: LSpacing.buttonRadius)
                }
                .bubblyTileLift()
            }
            .padding(.vertical, 6)
        }
    }

    private func headingTopPadding(for level: Int) -> CGFloat {
        level <= 2 ? 18 : 12
    }
}

private struct ReaderImageBlock: View {
    let url: URL
    let alt: String?
    let caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous)
                        .fill(LColors.raisedSurfaces)
                        .frame(minHeight: 180)
                        .overlay {
                            ProgressView()
                                .tint(LColors.primaryActions)
                        }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous))
                case .failure:
                    RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous)
                        .fill(LColors.raisedSurfaces)
                        .frame(minHeight: 140)
                        .overlay(alignment: .center) {
                            VStack(spacing: 8) {
                                Image("image")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(LColors.textSecondary)

                                Text("Image unavailable")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                            }
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .accessibilityLabel(alt ?? caption ?? "Article image")

            if let caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ReaderListView: View {
    let items: [ReaderListItem]
    let ordered: Bool
    let textSize: ReaderTextSize

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: ordered ? 0 : 10) {
                    Text(ordered ? "\(index + 1). " : "•")
                        .font(.system(
                            size: ordered ? textSize.bodySize : textSize.bodySize + 2,
                            weight: .black,
                            design: .rounded
                        ))
                        .foregroundStyle(ordered ? LColors.indicators : LColors.secondaryAccent)
                        .frame(width: ordered ? nil : 18, alignment: .trailing)

                    ReaderTextView(text: item.content, textSize: textSize)
                }
            }
        }
    }
}

private struct ReaderCodeBlock: View {
    let language: String?
    let code: String
    let textSize: ReaderTextSize

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                if let language {
                    Text(language.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.indicators)
                }

                ScrollView(.horizontal, showsIndicators: true) {
                    Text(code)
                        .font(.system(size: max(13, textSize.bodySize - 2), weight: .semibold, design: .monospaced))
                        .foregroundStyle(LColors.primaryText)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous)
                .strokeBorder(LColors.raisedSurfaces, lineWidth: 1)
        )
    }
}
