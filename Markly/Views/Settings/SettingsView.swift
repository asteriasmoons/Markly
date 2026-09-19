//
//  SettingsView.swift
//  Markly
//

import SwiftUI
import SafariServices

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showingSignInSheet = false
    @State private var showingSignOutSheet = false
    @State private var showingBugReport = false
    @State private var showingBetaFeedback = false
    @State private var showingFeatureRequest = false
    @State private var showingSubmittedReports = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection
                    accountSection
                    dataSection
                    supportSection
                    legalSection
                    versionSection
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveSheet(isPresented: $showingSignInSheet) {
            SignInView()
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.visible)
        }
        .adaptiveSheet(isPresented: $showingSignOutSheet) {
            SignOutView()
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .adaptiveSheet(isPresented: $showingBugReport) {
            BugReportView()
        }
        .adaptiveSheet(isPresented: $showingFeatureRequest) {
            FeatureRequestView()
        }
        .adaptiveSheet(isPresented: $showingBetaFeedback) {
            BetaFeedbackView()
        }
        .adaptiveSheet(isPresented: $showingSubmittedReports) {
            SubmittedReportsView()
        }
        .adaptiveSheet(isPresented: $showingPrivacyPolicy) {
            InAppBrowserView(url: URL(string: "https://docs.voxiverse.ink/privacy/markly")!)
        }
        .adaptiveSheet(isPresented: $showingTermsOfService) {
            InAppBrowserView(url: URL(string: "https://docs.voxiverse.ink/terms/markly")!)
        }
        .onAppear {
            if appState.pendingReportConversationID != nil {
                showingSubmittedReports = true
            }
        }
        .onChange(of: appState.pendingReportConversationID) { _, newValue in
            if newValue != nil {
                showingSubmittedReports = true
            }
        }
    }
}

// MARK: - Sections

private extension SettingsView {

    var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(LColors.secondaryAccent)

            Spacer()
        }
    }

    var accountSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {

                settingsHeader(
                    title: "Account",
                    icon: "userwavy",
                    accent: settingsAccent(at: 0)
                )

                if appState.isSignedIn {

                    SettingsRow(
                        icon: "checkwavy",
                        title: "Signed In",
                        subtitle: "Your bookmarks are connected to your account.",
                        accent: settingsAccent(at: 0)
                    )

                    NavigationLink {
                        CloudSyncView()
                    } label: {
                        SettingsRow(
                            icon: "cloud",
                            title: "Cloud Sync",
                            subtitle: "Manage syncing across devices.",
                            accent: settingsAccent(at: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingSignOutSheet = true
                    } label: {
                        SettingsRow(
                            icon: "xmark",
                            title: "Sign Out",
                            subtitle: "Disconnect this device.",
                            accent: settingsAccent(at: 2)
                        )
                    }
                    .buttonStyle(.plain)

                } else {

                    Button {
                        showingSignInSheet = true
                    } label: {
                        SettingsRow(
                            icon: "apple",
                            title: "Sign In With Apple",
                            subtitle: "Sync bookmarks across your devices.",
                            accent: settingsAccent(at: 0)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .settingsSectionAccent(settingsAccent(at: 0))
    }

    var dataSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {

                settingsHeader(
                    title: "Data",
                    icon: "blankfolder",
                    accent: settingsAccent(at: 1)
                )

                NavigationLink {
                    ExportBookmarksView()
                } label: {
                    SettingsRow(
                        icon: "share",
                        title: "Export Bookmarks",
                        subtitle: "Create a backup of your saved bookmarks.",
                        accent: settingsAccent(at: dataRowOffset)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ImportBookmarksView()
                } label: {
                    SettingsRow(
                        icon: "download",
                        title: "Import Bookmarks",
                        subtitle: "Import bookmarks from another source.",
                        accent: settingsAccent(at: dataRowOffset + 1)
                    )
                }
                .buttonStyle(.plain)

                SettingsRow(
                    icon: "reset",
                    title: "Refresh Shared Folders",
                    subtitle: "Update folders used by the share extension.",
                    accent: settingsAccent(at: dataRowOffset + 2)
                )
            }
        }
        .settingsSectionAccent(settingsAccent(at: 1))
    }

    var supportSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {

                settingsHeader(
                    title: "Support",
                    icon: "loveletter",
                    accent: settingsAccent(at: 2)
                )

                Button {
                    showingBugReport = true
                } label: {
                    SettingsRow(
                        icon: "bug",
                        title: "Report a Bug",
                        subtitle: "Let us know if something isn't working.",
                        accent: settingsAccent(at: supportRowOffset)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showingFeatureRequest = true
                } label: {
                    SettingsRow(
                        icon: "searchsparkle",
                        title: "Request a Feature",
                        subtitle: "Suggest improvements for Markly.",
                        accent: settingsAccent(at: supportRowOffset + 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showingBetaFeedback = true
                } label: {
                    SettingsRow(
                        icon: "chatlines",
                        title: "Beta Feedback",
                        subtitle: "Share what you tested and how it felt.",
                        accent: settingsAccent(at: supportRowOffset + 2)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showingSubmittedReports = true
                } label: {
                    SettingsRow(
                        icon: "inboxfill",
                        title: "Submitted Reports",
                        subtitle: "View reports sent from this device.",
                        accent: settingsAccent(at: supportRowOffset + 3)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .settingsSectionAccent(settingsAccent(at: 2))
    }

    var legalSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {

                settingsHeader(
                    title: "Legal",
                    icon: "docslove",
                    accent: settingsAccent(at: 3)
                )

                Button {
                    showingPrivacyPolicy = true
                } label: {
                    SettingsRow(
                        icon: "lovedotlist",
                        title: "Privacy Policy",
                        subtitle: "Read how your data is handled.",
                        accent: settingsAccent(at: legalRowOffset)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showingTermsOfService = true
                } label: {
                    SettingsRow(
                        icon: "lovedotlist",
                        title: "Terms of Service",
                        subtitle: "Review the terms of using Markly.",
                        accent: settingsAccent(at: legalRowOffset + 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .settingsSectionAccent(settingsAccent(at: 3))
    }

    var versionSection: some View {
        GlassCard {
            HStack {
                Text("Version")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(settingsAccent(at: 4))

                Spacer()

                Text("1.0")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
        .settingsSectionAccent(settingsAccent(at: 4))
    }

    var dataRowOffset: Int {
        appState.isSignedIn ? 3 : 1
    }

    var supportRowOffset: Int {
        dataRowOffset + 3
    }

    var legalRowOffset: Int {
        supportRowOffset + 4
    }

    func settingsAccent(at index: Int) -> Color {
        switch index % 3 {
        case 0:
            return LColors.primaryActions
        case 1:
            return LColors.secondaryAccent
        default:
            return LColors.indicators
        }
    }

    func settingsHeader(
        title: String,
        icon: String,
        accent: Color
    ) -> some View {
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

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {

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

            Image("chevright")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.textSecondary)
        }
    }
}

private extension View {
    func settingsSectionAccent(_ accent: Color) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        )
    }
}


// MARK: - In-App Browser

private struct InAppBrowserView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
