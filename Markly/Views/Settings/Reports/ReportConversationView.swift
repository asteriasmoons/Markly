//
//  ReportConversationView.swift
//  Markly
//

import QuickLook
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ReportConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var service = MarklyReportConversationService()
    @State private var draft = ""
    @State private var attachmentPreviewURL: URL?
    @State private var didPerformInitialScroll = false

    private let conversationBottomID = "markly-conversation-bottom"

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
        .quickLookPreview($attachmentPreviewURL)
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
                        Color.clear.frame(height: 1).id(conversationBottomID)
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                }
                .onAppear {
                    scrollToConversationBottom(using: proxy, animated: false)
                }
                .onChange(of: service.displayedMessages.count) { _, _ in
                    scrollToConversationBottom(using: proxy, animated: didPerformInitialScroll)
                    didPerformInitialScroll = true
                }
                .onChange(of: service.snapshot?.acceptsReplies) { _, acceptsReplies in
                    if acceptsReplies == false {
                        scrollToConversationBottom(using: proxy, animated: true)
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
            } else if currentState == .accepted && service.snapshot?.acceptsReplies == false {
                disabledReadOnlyComposer
            } else if currentState == .notStarted {
                disabledPreInviteComposer
            }
        }
    }

    private var bottomConversationBarIsVisible: Bool {
        guard !(service.isLoading && service.snapshot == nil) else { return false }
        return currentState == .accepted || currentState == .notStarted
    }

    private var disabledReadOnlyComposer: some View {
        MarklyConversationComposer(
            draft: $draft,
            isEnabled: false,
            isSending: false,
            disabledMessage: "Replies are currently turned off."
        ) { _, _ in false }
            .padding(.horizontal, LSpacing.pageHorizontal)
            .padding(.top, 10)
            .padding(.bottom, 24)
            .background(LColors.background.opacity(0.96))
            .accessibilityLabel("Conversation composer disabled while read only")
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            MarklyConversationLoadingRing()
            Text("Loading private conversation…")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scrollToConversationBottom(using proxy: ScrollViewProxy, animated: Bool) {
        Task { @MainActor in
            await Task.yield()
            await Task.yield()
            if animated {
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(conversationBottomID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(conversationBottomID, anchor: .bottom)
            }
        }
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
        MarklyConversationComposer(draft: $draft, isEnabled: false, isSending: false) { _, _ in false }
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

            if service.snapshot?.acceptsReplies == false {
                Text("This conversation is currently read only. Voxiverse can turn replies back on at any time.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .id("read-only-status")
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

            VStack(alignment: message.isFromReporter ? .trailing : .leading, spacing: 8) {
                VStack(alignment: message.isFromReporter ? .trailing : .leading, spacing: 5) {
                    Text(message.isFromReporter ? "You" : "Voxiverse")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(message.isFromReporter ? LColors.secondaryAccent : LColors.indicators)
                        .shadow(color: .black.opacity(0.65), radius: 2, x: 0, y: 2)

                    if !message.body.isEmpty {
                        Text(message.body)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.primaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    if message.isFromReporter && message.deliveryState != .sent {
                        HStack(spacing: 8) {
                            Text(message.deliveryState == .sending ? "Sending…" : "Failed to send")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(message.deliveryState == .failed ? LColors.danger : LColors.textSecondary)
                            if message.deliveryState == .failed {
                                Button("Retry") {
                                    service.retryReporterMessage(message.id, report: report, modelContext: modelContext)
                                }
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.primaryActions)
                                .buttonStyle(.plain)
                            }
                        }
                    }
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

                ForEach(message.attachments) { attachment in
                    Button {
                        openAttachment(attachment)
                    } label: {
                        attachmentLabel(attachment)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(attachment.name)")
                }
            }

            if !message.isFromReporter {
                Spacer(minLength: 42)
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let error = service.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            MarklyConversationComposer(draft: $draft, isEnabled: true, isSending: service.isSending) { message, attachments in
                service.sendReporterMessage(message, attachments: attachments, report: report, modelContext: modelContext)
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
        service.displayedMessages
    }

    private var firstStaffMessage: MarklyReportConversationMessage? {
        messages.first { $0.senderRole == .staff }
    }

    private var canSendMessages: Bool {
        currentState == .accepted && (service.snapshot?.acceptsReplies ?? true)
    }

    @ViewBuilder
    private func attachmentLabel(_ attachment: MarklyConversationAttachment) -> some View {
        if UTType(attachment.typeIdentifier)?.conforms(to: .image) == true,
           let image = UIImage(data: attachment.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 120, alignment: .top)
                .background(LColors.raisedSurfaces)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LColors.primaryActions, lineWidth: 2)
                }
                .shadow(color: LColors.primaryActions.opacity(0.3), radius: 6)
        } else {
            HStack(spacing: 8) {
                CustomAssetIcon(name: "attach", size: 16, tint: LColors.primaryActions)
                Text(attachment.name)
            }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.primaryText)
                .lineLimit(1)
                .padding(10)
                .background(LColors.raisedSurfaces, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func openAttachment(_ attachment: MarklyConversationAttachment) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(URL(fileURLWithPath: attachment.name).lastPathComponent)
            try attachment.data.write(to: url, options: .atomic)
            attachmentPreviewURL = url
        } catch {
            service.errorMessage = error.localizedDescription
        }
    }
}

private struct MarklyConversationLoadingRing: View {
    private let colors = [LColors.primaryActions, LColors.secondaryAccent, LColors.indicators]
    private let dotCount = 15

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<dotCount, id: \.self) { index in
                    let pulse = 0.72 + (0.28 * (cos((elapsed * 5.2) - (Double(index) * 0.48)) + 1) / 2)
                    Circle()
                        .fill(colors[index % colors.count].opacity(0.82))
                        .overlay {
                            BubblyIconMaterial(tint: colors[index % colors.count])
                                .clipShape(Circle())
                        }
                        .frame(width: 13, height: 13)
                        .scaleEffect(pulse)
                        .offset(y: -39)
                        .rotationEffect(.degrees(Double(index) * (360 / Double(dotCount))))
                }
            }
            .frame(width: 96, height: 96)
            .rotationEffect(.degrees(elapsed * 42))
        }
        .frame(width: 96, height: 96)
        .accessibilityLabel("Loading private conversation")
    }
}
