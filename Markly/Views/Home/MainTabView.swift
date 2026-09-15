//
//  MainTabView.swift
//  Markly
//

import SwiftUI
import SwiftData

enum MarklyTab: CaseIterable {
    case library
    case pins
    case activity
    case settings

    static let primaryTabs: [MarklyTab] = [
        .library,
        .pins,
        .activity,
        .settings
    ]

    static let overflowTabs: [MarklyTab] = []

    var icon: String {
        switch self {
        case .library:
            return "openbook"

        case .pins:
            return "pinfill"

        case .activity:
            return "sparkbolt"

        case .settings:
            return "cogwavy"
        }
    }

    var title: String {
        switch self {
        case .library:
            return "Library"

        case .pins:
            return "Pins"

        case .activity:
            return "Activity"

        case .settings:
            return "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .library:
            return "Browse every bookmark you have saved."

        case .pins:
            return "Browse your saved collections and pinned bookmarks."

        case .activity:
            return "See recent saves, imports, exports, and updates."

        case .settings:
            return "Manage Markly preferences and app settings."
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: MarklyTab = .library
    @EnvironmentObject private var appState: AppState
    @Query private var authUsers: [AuthUser]

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
        }
        .background {
            MarklyBackground()
                .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            if appState.currentUser == nil,
               let savedUser = authUsers.first {
                appState.setSignedIn(savedUser)
            }
        }
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .library:
            NavigationStack {
                BookmarksView()
            }

        case .pins:
            NavigationStack {
                PinsView()
            }

        case .activity:
            NavigationStack {
                ActivityPage()
            }

        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selectedTab: MarklyTab

    @State private var showMoreTabs = false

    private var primaryTabs: [MarklyTab] {
        MarklyTab.primaryTabs
    }

    private var overflowTabs: [MarklyTab] {
        MarklyTab.overflowTabs
    }

    private var leadingTabs: [MarklyTab] {
        Array(primaryTabs.prefix(2))
    }

    private var trailingTabs: [MarklyTab] {
        Array(primaryTabs.dropFirst(2))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if showMoreTabs && !overflowTabs.isEmpty {
                moreTabsMenu
                    .frame(maxWidth: 280)
                    .padding(.bottom, 116)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }

            HStack(spacing: 0) {
                ForEach(leadingTabs, id: \.self) { tab in
                    tabButton(tab)
                }

                centerAddButton

                ForEach(trailingTabs, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background {
                ZStack {
                    Capsule().fill(LColors.bg.opacity(0.95))

                    Capsule().fill(LColors.surfaces.opacity(0.68))

                    TriColorBorder(shape: Capsule(), lineWidth: 2.2)
                }
            }
            .frame(maxWidth: 330)
            .padding(.horizontal, 20)
            .padding(.bottom, 42)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showMoreTabs)
    }

    private func tabButton(_ tab: MarklyTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                selectedTab = tab
                showMoreTabs = false
            }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LColors.indicators.opacity(0.22))
                        .frame(width: 28, height: 24)
                }

                Image(tab.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(LColors.indicators)
                        : AnyShapeStyle(Color.white.opacity(0.4))
                    )
            }
            .frame(height: 24)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var centerAddButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                showMoreTabs.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(LColors.primaryActions)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .strokeBorder(LColors.indicators.opacity(0.72), lineWidth: 1.4)
                    )
                    .shadow(color: Color.black.opacity(0.24), radius: 10, x: 0, y: 5)

                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LColors.bg)
                    .rotationEffect(.degrees(showMoreTabs ? 45 : 0))
            }
            .frame(height: 42)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .opacity(1)
    }

    private var moreTabsMenu: some View {
        VStack(spacing: 6) {
            ForEach(overflowTabs, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        selectedTab = tab
                        showMoreTabs = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(tab.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(
                                selectedTab == tab
                                ? AnyShapeStyle(LColors.indicators)
                                : AnyShapeStyle(LColors.textSecondary)
                            )
                            .frame(width: 34, height: 34)
                            .background(
                                selectedTab == tab ? LColors.glassSurface2 : LColors.glassSurface,
                                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .strokeBorder(LColors.glassBorder, lineWidth: 1)
                            )

                        Text(tab.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textPrimary)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        selectedTab == tab ? LColors.glassSurface2.opacity(0.75) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LColors.bg.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LColors.surfaces.opacity(0.72))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1.4)
                )
        }
        .shadow(color: .black.opacity(0.24), radius: 22, x: 0, y: 12)
    }
}

// MARK: - Placeholder Tab View

struct PlaceholderTabView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(LColors.secondaryAccent)

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.horizontal, 40)

                Text("Coming soon")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.bottom, 90)
        }
    }
}
