//
//  DictionaryWordDetailView.swift
//  Markly
//

import SwiftUI

struct DictionaryWordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechReader = DictionarySpeechReader()

    let word: DictionaryWord
    let onEdit: () -> Void

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    topBadges
                    pronunciationCard
                    chipSection(title: "Synonyms", items: word.synonyms)
                    chipSection(title: "Antonyms", items: word.antonyms)
                    numberedCard(title: "Definitions", items: word.definitions, border: LColors.secondaryAccent)
                    numberedCard(title: "Example Sentences", items: word.exampleSentences, border: LColors.indicators)
                    paragraphCard(title: "Origin / Etymology", text: word.originEtymology, border: LColors.primaryActions)
                    chipSection(title: "Related Words", items: word.relatedWords)
                    usageNotesCard
                    chipSection(title: "Tags", items: word.tags)
                    metadataCard
                    editButton
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension DictionaryWordDetailView {
    var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(word.word)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(LColors.secondaryAccent)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismiss()
            } label: {
                CustomAssetIcon(name: "xmark", size: 30, tint: LColors.secondaryAccent)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    var topBadges: some View {
        DictionaryFlowLayout(spacing: 10, lineSpacing: 10) {
            DictionaryDetailPill(title: word.partOfSpeech, accent: LColors.primaryActions, icon: "tagsparkle")

            ForEach(Array(word.sources.enumerated()), id: \.offset) { _, source in
                let title = source.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Source" : source.name
                if let url = URL(string: source.url.trimmingCharacters(in: .whitespacesAndNewlines)), !source.url.isEmpty {
                    Link(destination: url) {
                        DictionaryDetailPill(title: title, accent: LColors.secondaryAccent, icon: "link")
                    }
                } else {
                    DictionaryDetailPill(title: title, accent: LColors.secondaryAccent, icon: "link")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var pronunciationCard: some View {
        DictionaryDetailBorderedCard(title: "Pronunciation", accent: LColors.secondaryAccent) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(pronunciationDisplay)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.primaryText)

                    if !word.ipaPronunciation.isEmpty {
                        Text(word.ipaPronunciation)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                Spacer()

                Button {
                    speechReader.speak(word.word)
                } label: {
                    CustomAssetIcon(name: "speaker", size: 20, tint: LColors.primaryText)
                        .frame(width: 46, height: 46)
                        .background {
                            BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: 16)
                        }
                        .bubblyTileLift()
                }
                .buttonStyle(.plain)
            }
        }
    }

    var usageNotesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Usage Notes")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.indicators)

            if word.usageNotes.isEmpty {
                emptyLine("No usage notes added yet.")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(word.usageNotes.enumerated()), id: \.offset) { index, note in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(note.label)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.primaryText.opacity(0.78))

                            Text(note.value)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                        .background {
                            BubblyTileSurface(tint: accent(for: index), cornerRadius: 16)
                        }
                        .bubblyTileLift()
                    }
                }
            }
        }
    }

    var metadataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Metadata")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.primaryActions)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                metadataTile(label: "Date Added", value: word.dateAdded.formatted(date: .abbreviated, time: .omitted), accent: LColors.primaryActions)
                metadataTile(label: "Modified", value: word.dateModified.formatted(date: .abbreviated, time: .omitted), accent: LColors.secondaryAccent)
            }
        }
    }

    var editButton: some View {
        Button {
            dismiss()
            onEdit()
        } label: {
            Text("Edit Word")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(LColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: LSpacing.buttonRadius)
                }
                .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }

    var pronunciationDisplay: String {
        let written = word.writtenPronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
        return written.isEmpty ? word.word : written
    }

    func chipSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(sectionAccent(for: title))

            if items.isEmpty {
                emptyLine("No \(title.lowercased()) added yet.")
            } else {
                DictionaryFlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        DictionaryDetailPill(title: item, accent: accent(for: index))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func numberedCard(title: String, items: [String], border: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(border)

            if items.isEmpty {
                GlassCard(cornerRadius: 22, padding: 14) {
                    emptyLine("No \(title.lowercased()) added yet.")
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(border, lineWidth: 1.2)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                Rectangle()
                                    .fill(border.opacity(0.16))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)

                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(.black)
                                    .frame(width: 46, height: 46)
                                    .background {
                                        UnevenRoundedRectangle(
                                            cornerRadii: .init(
                                                topLeading: 22,
                                                bottomLeading: 0,
                                                bottomTrailing: 20,
                                                topTrailing: 0
                                            ),
                                            style: .continuous
                                        )
                                        .fill(border)
                                    }
                            }

                            Text(item)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(LColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LColors.surfaces)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(border, lineWidth: 1.2)
                        }
                    }
                }
            }
        }
    }

    func paragraphCard(title: String, text: String, border: Color) -> some View {
        DictionaryDetailBorderedCard(title: title, accent: border) {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty {
                emptyLine("No origin or etymology added yet.")
            } else {
                Text(cleaned)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func metadataTile(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(LColors.primaryText.opacity(0.8))

            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(LColors.primaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .center)
        .padding(.horizontal, 12)
        .background {
            BubblyTileSurface(tint: accent, cornerRadius: 18)
        }
        .bubblyTileLift()
    }

    func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func accent(for index: Int) -> Color {
        switch index % 3 {
        case 1:
            return LColors.secondaryAccent
        case 2:
            return LColors.indicators
        default:
            return LColors.primaryActions
        }
    }

    func sectionAccent(for title: String) -> Color {
        switch title {
        case "Antonyms", "Definitions":
            return LColors.secondaryAccent
        case "Example Sentences", "Usage Notes":
            return LColors.indicators
        default:
            return LColors.primaryActions
        }
    }
}

private struct DictionaryDetailBorderedCard<Content: View>: View {
    let title: String
    let accent: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            GlassCard(cornerRadius: 22, padding: 14) {
                content()
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(accent, lineWidth: 1.2)
            }
        }
    }
}

private struct DictionaryDetailPill: View {
    let title: String
    let accent: Color
    var icon: String?

    var body: some View {
        HStack(spacing: 7) {
            if let icon {
                CustomAssetIcon(name: icon, size: 14, tint: LColors.primaryText)
            }

            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(LColors.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background {
            BubblyTileSurface(tint: accent, cornerRadius: 17)
        }
        .bubblyTileLift()
    }
}
