//
//  ReportConversationView.swift
//  Markly
//

import SwiftData
import SwiftUI

struct ReportConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var service = MarklyReportConversationService()
    @State private var draft = ""

    let report: SubmittedReport

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                MarklyReportHeader(
                    eyebrow: nil,
                    title: "Private Conversation",
                    titleColor: LColors.secondaryAccent,
                    closeColor: LColors.secondaryAccent,
                    closeIsIconOnly: true
                ) {
                    dismiss()
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 8)

                conversationBody
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomConversationBar
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await service.load(report: report, modelContext: modelContext, markRead: true)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: MarklyReportConversationNotificationManager.conversationDataDidChange
        )) { _ in
            Task {
                await service.load(report: report, modelContext: modelContext, markRead: true)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await service.load(report: report, modelContext: modelContext, markRead: true)
            }
        }
        .marklyDismissKeyboardOnOutsideTap()
    }

    @ViewBuilder
    private var conversationBody: some View {
        if service.isLoading && service.snapshot == nil {
            loadingState
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        reportContextCard
                        stateContent
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                }
                .onChange(of: service.snapshot?.messages.count ?? 0) { _, _ in
                    if let lastID = service.snapshot?.messages.last?.id {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var bottomConversationBar: some View {
        if bottomConversationBarIsVisible {
            if canSendMessages {
                composer
            } else if currentState == .notStarted {
                disabledPreInviteComposer
            }
        }
    }

    private var bottomConversationBarIsVisible: Bool {
        guard !(service.isLoading && service.snapshot == nil) else { return false }
        return canSendMessages || currentState == .notStarted
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(LColors.secondaryAccent)
            Text("Loading private conversation…")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reportContextCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(report.reportID)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(LColors.secondaryAccent)

                Text(report.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.primaryActions)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Private report conversation with Voxiverse.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1.2)
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        if let error = service.errorMessage {
            MarklyReportErrorCard(message: error)
        }

        switch currentState {
        case .notStarted:
            emptyState
        case .invited:
            invitationState
        case .accepted:
            messagesState
        case .declined:
            declinedState
        }
    }

    private var emptyState: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                BubblyIconMaterial(tint: LColors.indicators)
                    .mask {
                        Image("mailbox")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)
                Text("No invitation yet")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.primaryText)
                Text("If Voxiverse needs to privately discuss this report, the invitation and first message will appear here.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(LColors.secondaryAccent, lineWidth: 1.2)
        }
    }

    private var disabledPreInviteComposer: some View {
        let composerHeight: CGFloat = 86

        return HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LColors.raisedSurfaces)
                    .overlay {
                        BubblyTileSurface(tint: LColors.indicators, cornerRadius: 24)
                            .mask {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(lineWidth: 1.4)
                            }
                    }
                    .frame(height: composerHeight)

                Text("Waiting for Voxiverse to send the first message…")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                BubblyIconMaterial(tint: LColors.secondaryAccent)
                    .mask {
                        Image("expand")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 22, height: 22)
                    .padding(14)
                    .opacity(0.72)
                    .accessibilityHidden(true)
            }
            .opacity(0.72)

            VStack(spacing: 0) {
                BubblyIconMaterial(tint: LColors.primaryActions)
                    .mask {
                        Image("attach")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 30, height: 30)
                    .offset(y: 5)

                Spacer(minLength: 0)

                BubblyIconMaterial(tint: LColors.secondaryAccent)
                    .mask {
                        Image("send")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 28, height: 28)
                    .opacity(0.45)
                    .offset(y: -5)
            }
            .frame(width: 38, height: composerHeight)
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(LColors.background.opacity(0.96))
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Conversation composer disabled until Voxiverse sends an invitation")
    }

    private var invitationState: some View {
        VStack(alignment: .center, spacing: 14) {
            GlassCard(cornerRadius: 24) {
                VStack(alignment: .center, spacing: 16) {
                    BubblyIconMaterial(tint: LColors.indicators)
                        .mask {
                            Image("starmailing")
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(width: 38, height: 38)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("Voxiverse sent you a message")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.indicators)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("The Voxiverse team invited you to a private conversation about this submitted report.")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 4) {
                        Text(report.reportID)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(LColors.indicators)
                            .multilineTextAlignment(.center)

                        Text(report.title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.secondaryAccent)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(LColors.raisedSurfaces, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(LColors.indicators, lineWidth: 1.2)
                    }

                    Text("Accepting lets you reply in this private thread. Declining closes the invitation.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if service.isUpdatingInvitation {
                        ProgressView()
                            .tint(LColors.secondaryAccent)
                            .accessibilityLabel("Updating invitation")
                    }

                    VStack(spacing: 10) {
                        Button {
                            Task { await service.accept(report: report, modelContext: modelContext) }
                        } label: {
                            Text("Accept")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.primaryText)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background {
                                    BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: 18)
                                }
                                .bubblyTileLift()
                        }
                        .buttonStyle(.plain)
                        .disabled(service.isUpdatingInvitation)
                        .accessibilityLabel("Accept private conversation invitation")

                        Button {
                            Task { await service.decline(report: report, modelContext: modelContext) }
                        } label: {
                            Text("Decline")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.primaryText)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background {
                                    BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: 18)
                                }
                                .bubblyTileLift()
                        }
                        .buttonStyle(.plain)
                        .disabled(service.isUpdatingInvitation)
                        .accessibilityLabel("Decline private conversation invitation")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(LColors.secondaryAccent, lineWidth: 1.2)
            }

            if let firstMessage = firstStaffMessage {
                messageBubble(firstMessage)
                    .id(firstMessage.id)
            }
        }
    }

    private var messagesState: some View {
        VStack(alignment: .leading, spacing: 12) {
            if messages.isEmpty {
                GlassCard(cornerRadius: 24) {
                    Text("No messages yet.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(messages) { message in
                    messageBubble(message)
                        .id(message.id)
                }
            }
        }
    }

    private var declinedState: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                CustomAssetIcon(name: "xmark", size: 26, tint: LColors.indicators)
                Text("Invitation declined")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.primaryText)
                Text("This report conversation is closed on your side. Voxiverse can see that you declined.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func messageBubble(_ message: MarklyReportConversationMessage) -> some View {
        HStack(alignment: .bottom) {
            if message.isFromReporter {
                Spacer(minLength: 42)
            }

            VStack(alignment: message.isFromReporter ? .trailing : .leading, spacing: 5) {
                Text(message.isFromReporter ? "You" : "Voxiverse")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.indicators)

                Text(message.body)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.primaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .padding(13)
            .background {
                BubblyTileSurface(
                    tint: message.isFromReporter ? LColors.indicators : LColors.secondaryAccent,
                    cornerRadius: 20
                )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(message.isFromReporter ? LColors.indicators.opacity(0.7) : LColors.secondaryAccent.opacity(0.7), lineWidth: 1)
            }
            .bubblyTileLift()

            if !message.isFromReporter {
                Spacer(minLength: 42)
            }
        }
    }

    private var composer: some View {
        let composerHeight: CGFloat = 86

        return VStack(spacing: 8) {
            if let error = service.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LColors.raisedSurfaces)
                        .overlay {
                            BubblyTileSurface(tint: LColors.indicators, cornerRadius: 24)
                                .mask {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .strokeBorder(lineWidth: 1.4)
                                }
                        }

                    TextEditor(text: $draft)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.primaryText)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .padding(.trailing, 34)

                    if draft.trimmed.isEmpty {
                        Text("Reply to Voxiverse…")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .allowsHitTesting(false)
                    }

                    BubblyIconMaterial(tint: LColors.secondaryAccent)
                        .mask {
                            Image("expand")
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(width: 22, height: 22)
                        .padding(14)
                        .accessibilityHidden(true)
                }
                .frame(height: composerHeight)

                VStack(spacing: 0) {
                    Button(action: {}) {
                        BubblyIconMaterial(tint: LColors.primaryActions)
                            .mask {
                                Image("attach")
                                    .resizable()
                                    .scaledToFit()
                            }
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    .offset(y: 5)
                    .accessibilityLabel("Message attachments are not available")

                    Spacer(minLength: 0)

                    Button {
                        let message = draft
                        draft = ""
                        Task { await service.sendReporterMessage(message, report: report, modelContext: modelContext) }
                    } label: {
                        BubblyIconMaterial(tint: LColors.secondaryAccent)
                            .mask {
                                Image("send")
                                    .resizable()
                                    .scaledToFit()
                            }
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(draft.trimmed.isEmpty || service.isSending)
                    .opacity(draft.trimmed.isEmpty || service.isSending ? 0.45 : 1)
                    .offset(y: -5)
                    .accessibilityLabel("Send message")
                }
                .frame(width: 38, height: composerHeight)
            }
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(LColors.background.opacity(0.96))
    }

    private var currentState: MarklyReportConversationState {
        service.snapshot?.state ?? report.conversationState
    }

    private var messages: [MarklyReportConversationMessage] {
        service.snapshot?.messages ?? []
    }

    private var firstStaffMessage: MarklyReportConversationMessage? {
        messages.first { $0.senderRole == .staff }
    }

    private var canSendMessages: Bool {
        currentState == .accepted
    }
}
