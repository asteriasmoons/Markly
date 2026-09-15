//
//  ReaderView.swift
//  Markly
//

import SwiftUI
import UIKit

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReaderViewModel
    @AppStorage("markly.reader.textSize") private var textSizeRawValue: String = ReaderTextSize.normal.rawValue

    let sourceURL: URL

    @State private var readingProgress: CGFloat = 0
    @State private var contentHeight: CGFloat = 1
    @State private var viewportHeight: CGFloat = 1

    init(sourceURL: URL) {
        self.sourceURL = sourceURL
        _viewModel = StateObject(wrappedValue: ReaderViewModel(sourceURL: sourceURL))
    }

    var body: some View {
        ZStack(alignment: .top) {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.bottom, 10)

                progressBar

                content
            }
        }
        .task {
            viewModel.load()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private var textSize: ReaderTextSize {
        ReaderTextSize(rawValue: textSizeRawValue) ?? .normal
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.cancel()
                dismiss()
            } label: {
                Image("xmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LColors.secondaryAccent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close reader")

            Spacer()

            Button {
                openOriginal()
            } label: {
                ReaderToolbarButton(title: "Original", icon: "browsericon", tint: LColors.primaryActions)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open original article")

            Menu {
                ForEach(ReaderTextSize.allCases) { option in
                    Button(option.label) {
                        textSizeRawValue = option.rawValue
                    }
                }
            } label: {
                ReaderToolbarButton(title: textSize.label, icon: "pencil", tint: LColors.secondaryAccent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reader text size")
        }
        .padding(.top, 8)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(LColors.raisedSurfaces.opacity(0.7))

                Rectangle()
                    .fill(LColors.indicators)
                    .frame(width: proxy.size.width * readingProgress)
            }
        }
        .frame(height: 3)
        .accessibilityLabel("Reading progress")
        .accessibilityValue("\(Int(readingProgress * 100)) percent")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingState
        case .loaded(let article):
            articleView(article)
        case .failed:
            unavailableState
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(LColors.primaryActions)

                        Text("Preparing reader...")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.primaryText)
                    }

                    Text("Markly is extracting the readable article and removing page clutter.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, LSpacing.pageHorizontal)

            Spacer()
        }
    }

    private var unavailableState: some View {
        VStack {
            Spacer()

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    Image("ebook")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .foregroundStyle(LColors.indicators)

                    Text("Reader view isn't available for this page.")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.primaryText)

                    Text("Some dashboards, stores, login pages, social feeds, and heavily scripted pages do not expose readable article content.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        LButton(title: "Open Original", icon: "browsericon", style: .primary) {
                            openOriginal()
                        }

                        Button {
                            dismiss()
                        } label: {
                            ReaderToolbarButton(title: "Close", icon: "xmark", tint: LColors.secondaryAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, LSpacing.pageHorizontal)

            Spacer()
        }
    }

    private func articleView(_ article: ReaderArticle) -> some View {
        GeometryReader { viewport in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ReaderScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("readerScroll")).minY
                            )
                    }
                    .frame(height: 0)

                    articleHeader(article)

                    if let heroImageURL = article.heroImageURL {
                        ReaderHeroImage(url: heroImageURL)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(article.blocks.enumerated()), id: \.offset) { _, block in
                            ReaderBlockView(block: block, textSize: textSize)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.bottom, 150)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ReaderContentHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
            }
            .coordinateSpace(name: "readerScroll")
            .onAppear {
                viewportHeight = viewport.size.height
            }
            .onChange(of: viewport.size.height) { _, newValue in
                viewportHeight = newValue
                updateProgress(offset: 0)
            }
            .onPreferenceChange(ReaderContentHeightPreferenceKey.self) { height in
                contentHeight = max(1, height)
            }
            .onPreferenceChange(ReaderScrollOffsetPreferenceKey.self) { offset in
                updateProgress(offset: offset)
            }
        }
    }

    private func articleHeader(_ article: ReaderArticle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(article.title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(LColors.secondaryAccent)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            FlowMetadataRow(article: article)

            if let excerpt = article.excerpt {
                Text(excerpt)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func updateProgress(offset: CGFloat) {
        let distance = max(0, -offset)
        let available = max(1, contentHeight - viewportHeight)
        readingProgress = min(1, max(0, distance / available))
    }

    private func openOriginal() {
        UIApplication.shared.open(sourceURL)
    }
}

private struct FlowMetadataRow: View {
    let article: ReaderArticle

    var body: some View {
        ReaderFlowLayout(spacing: 8) {
            ReaderMetadataTile(
                icon: "link",
                text: article.siteName ?? article.sourceHost,
                tint: LColors.primaryActions
            )

            if let byline = article.byline {
                ReaderMetadataTile(icon: "userwavy", text: byline, tint: LColors.secondaryAccent)
            }

            ReaderMetadataTile(
                icon: "clockfill",
                text: "\(article.estimatedReadingMinutes) min read",
                tint: LColors.indicators
            )

            if let publishedDate = article.publishedDate {
                ReaderMetadataTile(
                    icon: "calendarfill",
                    text: publishedDate.formatted(date: .abbreviated, time: .omitted),
                    tint: LColors.primaryActions
                )
            }
        }
    }
}

private struct ReaderMetadataTile: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 13, height: 13)
                .foregroundStyle(LColors.primaryText)

            Text(text)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 999)
        }
        .bubblyTileLift()
    }
}

private struct ReaderToolbarButton: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
        }
        .foregroundStyle(LColors.primaryText)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: LSpacing.buttonRadius)
        }
        .bubblyTileLift()
    }
}

private struct ReaderHeroImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: LSpacing.cardRadius, style: .continuous)
                    .fill(LColors.raisedSurfaces)
                    .frame(minHeight: 210)
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
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
        .accessibilityLabel("Article image")
    }
}

private struct ReaderContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 1

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ReaderScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ReaderFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
