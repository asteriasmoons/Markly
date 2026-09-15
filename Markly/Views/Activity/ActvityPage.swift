//
//  ActvityPage.swift
//  Markly
//

import SwiftUI
import SwiftData

// MARK: - Activity Page

struct ActivityPage: View {

    @Query private var bookmarks: [BookmarkItem]
    @Query private var folders: [BookmarkFolder]
    @Query private var pinCollections: [PinCollection]

    private var stats: [ActivityStat] {
        [
            ActivityStat(
                title: "Folders",
                value: folders.count,
                icon: "starfolder",
                isCustomIcon: true
            ),
            ActivityStat(
                title: "Bookmarks",
                value: bookmarks.count,
                icon: "starmark",
                isCustomIcon: true
            ),
            ActivityStat(
                title: "Collections",
                value: pinCollections.count,
                icon: "boxstack",
                isCustomIcon: true
            )
        ]
    }

    private var bookmarkActivities: [ActivityDisplayItem] {
        bookmarks.map { bookmark in
            ActivityDisplayItem(
                title: "Bookmark saved",
                subtitle: displayTitle(for: bookmark, fallback: "Saved bookmark"),
                icon: "starmark",
                isCustomIcon: true,
                timestamp: displayDate(for: bookmark),
                type: .saved
            )
        }
    }

    private var folderActivities: [ActivityDisplayItem] {
        folders.map { folder in
            ActivityDisplayItem(
                title: "Folder available",
                subtitle: displayTitle(for: folder, fallback: "Bookmark folder"),
                icon: "starfolder",
                isCustomIcon: true,
                timestamp: displayDate(for: folder),
                type: .collections
            )
        }
    }

    private var collectionActivities: [ActivityDisplayItem] {
        pinCollections.map { collection in
            ActivityDisplayItem(
                title: "Collection available",
                subtitle: displayTitle(for: collection, fallback: "Pin collection"),
                icon: "boxstack",
                isCustomIcon: true,
                timestamp: displayDate(for: collection),
                type: .collections
            )
        }
    }

    private var allActivityItems: [ActivityDisplayItem] {
        (bookmarkActivities + folderActivities + collectionActivities)
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var filteredActivities: [ActivityDisplayItem] {
        allActivityItems
    }

    private func displayTitle(for object: Any, fallback: String) -> String {
        stringValue(from: object, keys: ["title", "name", "label", "displayName"])
        ?? stringValue(from: object, keys: ["url", "link"])
        ?? fallback
    }

    private func displayDate(for object: Any) -> Date {
        dateValue(from: object, keys: ["updatedAt", "createdAt", "dateCreated", "timestamp", "date"])
        ?? .now
    }

    private func stringValue(from object: Any, keys: [String]) -> String? {
        let mirror = Mirror(reflecting: object)

        for child in mirror.children {
            guard let label = child.label, keys.contains(label) else { continue }

            if let value = child.value as? String, !value.isEmpty {
                return value
            }

            if let value = child.value as? URL {
                return value.absoluteString
            }
        }

        return nil
    }

    private func dateValue(from object: Any, keys: [String]) -> Date? {
        let mirror = Mirror(reflecting: object)

        for child in mirror.children {
            guard let label = child.label, keys.contains(label) else { continue }

            if let value = child.value as? Date {
                return value
            }
        }

        return nil
    }

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        statsGrid
                        recentActivitySection
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.bottom, 120)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Sections

private extension ActivityPage {

    var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Activity")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)

                Text("See what you’ve saved, opened, edited, and organized inside Markly.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
    }

    var statsGrid: some View {
        HStack(spacing: 10) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                ActivityStatTile(
                    stat: stat,
                    tint: statTileTint(at: index)
                )
            }
        }
    }

    func statTileTint(at index: Int) -> Color {
        switch index {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassCard {
                HStack(spacing: 12) {
                    ActivityAccentIcon(
                        icon: "levelup",
                        isCustom: true,
                        size: 21,
                        boxSize: 42,
                        accent: LColors.primaryActions
                    )

                    Text("Recent Activity")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.secondaryAccent)

                    Spacer()

                    Text("\(filteredActivities.count)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.primaryText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background {
                            BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: 999)
                        }
                        .bubblyTileLift()
                }
            }

            if filteredActivities.isEmpty {
                EmptyActivityCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredActivities) { item in
                        ActivityRow(
                            item: item,
                            accent: activityAccent(for: item.type)
                        )
                    }
                }
            }
        }
    }

    func activityAccent(for type: ActivityFilter) -> Color {
        switch type {
        case .saved, .bookmarks:
            return LColors.primaryActions
        case .collections:
            return LColors.secondaryAccent
        case .opened, .imported, .exported, .all:
            return LColors.indicators
        }
    }
}

// MARK: - Activity Display Item

private struct ActivityDisplayItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let isCustomIcon: Bool
    let timestamp: Date
    let type: ActivityFilter
}

// MARK: - Stat Card

private struct ActivityStatTile: View {
    let stat: ActivityStat
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(stat.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Spacer(minLength: 0)
            }

            Text("\(stat.value)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(stat.title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(LColors.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 20)
        }
        .bubblyTileLift()
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let item: ActivityDisplayItem
    let accent: Color

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ActivityAccentIcon(
                    icon: item.icon,
                    isCustom: item.isCustomIcon,
                    size: 22,
                    boxSize: 48,
                    accent: accent
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Text(item.timestamp, style: .relative)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .activityCardAccent(accent)
    }
}

// MARK: - Empty Activity Card

private struct EmptyActivityCard: View {
    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ActivityAccentIcon(
                    icon: "emptyinbox",
                    isCustom: true,
                    size: 24,
                    boxSize: 48,
                    accent: LColors.indicators
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("No activity yet")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.indicators)

                    Text("Your real saved, opened, and organized bookmark activity will show here once it exists.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Accent Icon

private struct ActivityAccentIcon: View {
    let icon: String
    let isCustom: Bool
    let size: CGFloat
    let boxSize: CGFloat
    let accent: Color

    var body: some View {
        ZStack {
            BubblyTileSurface(tint: accent, cornerRadius: boxSize / 2)
                .clipShape(Circle())

            Group {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
            }
            .foregroundStyle(.white)
            .frame(width: size, height: size)
        }
        .frame(width: boxSize, height: boxSize)
        .overlay {
            Circle()
                .strokeBorder(accent, lineWidth: 1.5)
        }
        .bubblyTileLift()
    }
}

private extension View {
    func activityCardAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActivityPage()
    }
}
