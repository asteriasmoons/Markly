//
//  ReportConversationButton.swift
//  Markly
//

import SwiftUI

struct ReportConversationButton: View {
    let state: MarklyReportConversationState
    let unreadCount: Int
    let action: () -> Void

    private var title: String {
        switch state {
        case .notStarted:
            return "Private Conversation"
        case .invited:
            return "Voxiverse Sent You a Message"
        case .accepted:
            return unreadCount > 0 ? "New Message from Voxiverse" : "Conversation with Voxiverse"
        case .declined:
            return "Conversation Declined"
        }
    }

    private var subtitle: String {
        switch state {
        case .notStarted:
            return "If Voxiverse needs details, the message will appear here."
        case .invited:
            return "Review the invitation for this report."
        case .accepted:
            return unreadCount > 0 ? "\(unreadCount) unread" : "Open your private report thread."
        case .declined:
            return "You declined this private report conversation."
        }
    }

    private var accent: Color {
        switch state {
        case .notStarted:
            return LColors.primaryActions
        case .invited, .accepted:
            return LColors.secondaryAccent
        case .declined:
            return LColors.indicators
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    CustomAssetIcon(name: "starchat", size: 24, tint: LColors.primaryText)
                        .frame(width: 52, height: 52)
                        .background {
                            BubblyTileSurface(tint: accent, cornerRadius: 20)
                        }
                        .bubblyTileLift()

                    if state == .invited || unreadCount > 0 {
                        Circle()
                            .fill(unreadCount > 0 ? LColors.indicators : accent)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(LColors.background, lineWidth: 2))
                            .accessibilityHidden(true)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                CustomAssetIcon(name: "chevright", size: 17, tint: accent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                BubblyTileSurface(tint: accent, cornerRadius: 24)
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}
