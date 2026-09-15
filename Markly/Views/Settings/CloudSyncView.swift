//
//  CloudSyncView.swift
//  Markly
//

import SwiftUI
import SwiftData

struct CloudSyncView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var bookmarks: [BookmarkItem]
    @Query private var folders: [BookmarkFolder]

    @State private var showingSignInSheet = false
    @State private var statusMessage: String = "Ready"
    @State private var lastRefreshDate: Date?

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                headerSection

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        accountCard
                        syncStatusCard
                        syncDataCard
                        actionsCard
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.bottom, 120)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveSheet(isPresented: $showingSignInSheet) {
            SignInView()
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Sections

private extension CloudSyncView {
    var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Cloud Sync")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)

                Text("Keep your Markly library available across your devices.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image("xmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(LColors.secondaryAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
        .padding(.top, 0)
    }

    var accountCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Account", icon: "checkwavy", accent: cloudSyncAccent(at: 0))

                if appState.isSignedIn {
                    InfoRow(
                        icon: "checkwavy",
                        title: "Signed In",
                        subtitle: "Your Markly session is active.",
                        accent: cloudSyncAccent(at: 0)
                    )

                    if let appleUserId = appState.currentAppleUserId {
                        Text("Apple ID: \(appleUserId)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                    }
                } else {
                    InfoRow(
                        icon: "xmark",
                        title: "Not Signed In",
                        subtitle: "Sign in with Apple to use cloud syncing.",
                        accent: cloudSyncAccent(at: 0)
                    )

                    Button {
                        showingSignInSheet = true
                    } label: {
                        Text("Sign In With Apple")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.background)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(LColors.indicators, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(cloudSyncAccent(at: 1).opacity(0.55), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cloudSyncSectionAccent(cloudSyncAccent(at: 0))
    }

    var syncStatusCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Sync Status", icon: "savesparkle", accent: cloudSyncAccent(at: 1))

                InfoRow(
                    icon: appState.isSignedIn ? "checkwavy" : "xmark",
                    title: appState.isSignedIn ? "Cloud Ready" : "Cloud Paused",
                    subtitle: appState.isSignedIn
                    ? "SwiftData and CloudKit can sync your saved Markly data."
                    : "Sign in first so Markly can keep your data connected.",
                    accent: cloudSyncAccent(at: 1)
                )

                InfoRow(
                    icon: "blankfolder",
                    title: "Shared Folders",
                    subtitle: "Folders are exported for the share extension.",
                    accent: cloudSyncAccent(at: 2)
                )

                Text(statusMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                if let lastRefreshDate {
                    Text("Last refreshed: \(lastRefreshDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.75))
                }
            }
        }
        .cloudSyncSectionAccent(cloudSyncAccent(at: 1))
    }

    var syncDataCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Synced Data", icon: "books", accent: cloudSyncAccent(at: 2))

                HStack(spacing: 12) {
                    CountTile(title: "Bookmarks", count: bookmarks.count, accent: cloudSyncAccent(at: 2))
                    CountTile(title: "Folders", count: folders.count, accent: cloudSyncAccent(at: 3))
                }

                Text("Markly syncs your saved links, folders, tags, notes, favorites, archive state, and link metadata.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cloudSyncSectionAccent(cloudSyncAccent(at: 2))
    }

    var actionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(title: "Actions", icon: "cogwavy", accent: cloudSyncAccent(at: 3))

                Button {
                    saveLocalChanges()
                } label: {
                    ActionRow(
                        icon: "checkwavy",
                        title: "Save Local Changes",
                        subtitle: "Force Markly to save the current local data state.",
                        accent: cloudSyncAccent(at: 3)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    refreshSharedFolders()
                } label: {
                    ActionRow(
                        icon: "blankfolder",
                        title: "Refresh Shared Folders",
                        subtitle: "Update the folders available inside the share extension.",
                        accent: cloudSyncAccent(at: 4)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    importPendingSharedBookmark()
                } label: {
                    ActionRow(
                        icon: "savesparkle",
                        title: "Import Pending Share",
                        subtitle: "Pull in a bookmark saved from the iOS share sheet.",
                        accent: cloudSyncAccent(at: 5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .cloudSyncSectionAccent(cloudSyncAccent(at: 3))
    }
}

// MARK: - Actions

private extension CloudSyncView {
    func saveLocalChanges() {
        do {
            try modelContext.save()
            statusMessage = "Local changes saved."
            lastRefreshDate = Date()
        } catch {
            statusMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func refreshSharedFolders() {
        SharedFolderExportManager.exportFolders(modelContext: modelContext)
        statusMessage = "Shared folders refreshed."
        lastRefreshDate = Date()
    }

    func importPendingSharedBookmark() {
        SharedBookmarkImportManager.importPendingBookmark(modelContext: modelContext)
        statusMessage = "Checked for pending shared bookmarks."
        lastRefreshDate = Date()
    }

    func cloudSyncAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    func sectionHeader(title: String, icon: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(accent)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(accent)
        }
    }
}

// MARK: - Supporting Views

private struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            MarklySettingsIcon(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(accent)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

private struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            MarklySettingsIcon(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(accent)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

private struct CountTile: View {
    let title: String
    let count: Int
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(count)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}

private struct MarklySettingsIcon: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            BubblyTileSurface(tint: accent, cornerRadius: 19)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(accent, lineWidth: 1.6)
                )

            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.primaryText)
        }
        .frame(width: 38, height: 38)
        .bubblyTileLift()
    }
}

private extension View {
    func cloudSyncSectionAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}
