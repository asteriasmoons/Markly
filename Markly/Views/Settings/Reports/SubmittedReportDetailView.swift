//
//  SubmittedReportDetailView.swift
//  Markly
//

import SwiftUI
import SwiftData
import UIKit

struct SubmittedReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    let report: SubmittedReport
    @State private var selectedAttachment: SubmittedReportAttachment?
    @State private var showConversation = false
    @State private var conversationState: MarklyReportConversationState
    @State private var conversationUnreadCount: Int
    @State private var didHandleInitialConversationOpen = false
    @StateObject private var conversationService = MarklyReportConversationService()

    let openConversationOnAppear: Bool
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let attachmentColumns = [
        GridItem(.adaptive(minimum: 112, maximum: 112), spacing: 12)
    ]

    init(report: SubmittedReport, openConversationOnAppear: Bool = false) {
        self.report = report
        self.openConversationOnAppear = openConversationOnAppear
        _conversationState = State(initialValue: report.conversationState)
        _conversationUnreadCount = State(initialValue: report.conversationUnreadCount)
    }

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                    MarklyReportHeader(
                        eyebrow: report.reportType,
                        title: report.title,
                        titleColor: LColors.secondaryAccent,
                        closeColor: LColors.secondaryAccent,
                        closeIsIconOnly: true
                    ) {
                        dismiss()
                    }

                    ReportConversationButton(
                        state: conversationState,
                        unreadCount: conversationUnreadCount
                    ) {
                        showConversation = true
                    }

                    reportDetails
                    attachmentsSection
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveSheet(item: $selectedAttachment) { attachment in
            SubmittedReportImageView(attachment: attachment)
        }
        .adaptiveSheet(isPresented: $showConversation, onDismiss: {
            refreshConversationSummary()
        }) {
            ReportConversationView(report: report)
        }
        .task {
            await refreshConversationSummaryAsync()
            openInitialConversationIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: MarklyReportConversationNotificationManager.conversationDataDidChange
        )) { _ in
            refreshConversationSummary()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshConversationSummary()
        }
    }

    private func refreshConversationSummary() {
        Task {
            await refreshConversationSummaryAsync()
        }
    }

    private func refreshConversationSummaryAsync() async {
        let summary = await conversationService.fetchSummary(for: report, modelContext: modelContext)
        conversationState = summary.state
        conversationUnreadCount = summary.reporterUnreadCount
    }

    private func openInitialConversationIfNeeded() {
        guard openConversationOnAppear, !didHandleInitialConversationOpen else { return }
        didHandleInitialConversationOpen = true
        showConversation = true
    }

    @ViewBuilder
    private var reportDetails: some View {
        if report.reportType == "Feature Request" {
            featureRequestDetails
        } else if report.reportType == "Beta Feedback" {
            betaFeedbackDetails
        } else {
            bugReportDetails
        }
    }

    private var featureRequestDetails: some View {
        VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "Submitted", value: report.submittedAt.formatted(date: .abbreviated, time: .omitted), index: 0)
                metadataTile(label: "Report ID", value: report.reportID, index: 1)
                metadataTile(label: "Area", value: report.category, index: 2)
                metadataTile(label: "Feature Type", value: report.featureType, index: 3)
                metadataTile(label: "Importance", value: report.featureImportance, index: 4)
                metadataTile(label: "Who Is This For?", value: report.intendedAudience, index: 5)
                metadataTile(label: "Where Should It Live?", value: report.desiredLocation, index: 6)
                metadataTile(label: "Saved Data", value: report.requiresSavedData, index: 7)
                metadataTile(label: "Notifications", value: report.needsNotifications, index: 8)
                metadataTile(label: "Sharing", value: report.needsSharing, index: 9)
                metadataTile(label: "AI", value: report.needsAI, index: 10)
            }

            reportTextSection(title: "What Should the Feature Do?", text: report.featureDescription, accent: LColors.primaryActions)
            reportTextSection(title: "How Should It Work?", text: report.imaginedWorkflow, accent: LColors.secondaryAccent)

            if !report.relatedExistingFeature.trimmed.isEmpty {
                reportTextSection(title: "Related Existing Feature", text: report.relatedExistingFeature, accent: LColors.indicators)
            }

            reportTextSection(title: "Problem or Limitation", text: report.problemAddressed, accent: LColors.primaryActions)
            reportTextSection(title: "Desired Result", text: report.desiredResult, accent: LColors.secondaryAccent)

            if !report.additionalDetails.trimmed.isEmpty {
                reportTextSection(title: "Additional Details", text: report.additionalDetails, accent: LColors.indicators)
            }

            diagnosticsSection
        }
    }

    private var betaFeedbackDetails: some View {
        VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "Submitted", value: report.submittedAt.formatted(date: .abbreviated, time: .omitted), index: 0)
                metadataTile(label: "Report Type", value: report.reportType, index: 1)
                metadataTile(label: "Area", value: report.category, index: 2)
                metadataTile(label: "Experience", value: report.overallExperience, index: 3)
                metadataTile(label: "Report ID", value: report.reportID, index: 4)
            }

            reportTextSection(title: "What Did You Test?", text: report.testedWhat, accent: LColors.primaryActions)
            reportTextSection(title: "What Worked Well?", text: report.workedWell, accent: LColors.secondaryAccent)
            reportTextSection(title: "What Could Be Better?", text: report.couldBeBetter, accent: LColors.indicators)
            reportTextSection(title: "Anything Unexpected?", text: report.unexpected, accent: LColors.primaryActions)
            reportTextSection(title: "Additional Thoughts", text: report.additionalNotes, accent: LColors.secondaryAccent)
            diagnosticsSection
        }
    }

    private var bugReportDetails: some View {
        VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "Submitted", value: report.submittedAt.formatted(date: .abbreviated, time: .omitted), index: 0)
                metadataTile(label: "Status", value: report.status, index: 1)
                metadataTile(label: "Area", value: report.category, index: 2)
                metadataTile(label: "Severity", value: report.severity, index: 3)
                metadataTile(label: "Frequency", value: report.frequency, index: 4)
                metadataTile(label: "Report ID", value: report.reportID, index: 5)
            }

            reportTextSection(title: "What Happened", text: report.descriptionText, accent: LColors.primaryActions)
            reportTextSection(title: "Expected Behavior", text: report.expectedBehavior, accent: LColors.secondaryAccent)

            if !report.steps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    MarklyReportSectionHeader(title: "Steps to Reproduce", color: LColors.indicators)
                    GlassCard(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(report.steps.indices, id: \.self) { index in
                                HStack(alignment: .center, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.background)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            BubblyTileSurface(tint: LColors.indicators, cornerRadius: 14)
                                                .clipShape(Circle())
                                        )

                                    Text(report.steps[index])
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(LColors.indicators, lineWidth: 1.2)
                    }
                }
            }

            reportTextSection(title: "Additional Notes", text: report.additionalNotes, accent: LColors.primaryActions)
            diagnosticsSection
        }
    }

    @ViewBuilder
    private var attachmentsSection: some View {
        if !report.attachments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                MarklyReportSectionHeader(title: report.reportType == "Feature Request" ? "Reference Images" : "Attachments", color: LColors.indicators)

                LazyVGrid(columns: attachmentColumns, alignment: .leading, spacing: 12) {
                    ForEach(report.attachments.sorted { $0.createdAt < $1.createdAt }) { attachment in
                        Button {
                            selectedAttachment = attachment
                        } label: {
                            SubmittedReportAttachmentCard(attachment: attachment)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MarklyReportSectionHeader(title: "Diagnostics", color: LColors.secondaryAccent)
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "App", value: report.appName, index: 0)
                metadataTile(label: "Version", value: report.appVersion, index: 1)
                metadataTile(label: "Build", value: report.buildNumber, index: 2)
                metadataTile(label: "Device", value: report.deviceModel, index: 3)
                metadataTile(label: "iOS", value: report.iOSVersion, index: 4)
                metadataTile(label: "Screen", value: displayScreenName, index: 5)
            }
        }
    }

    private var displayScreenName: String {
        let trimmed = report.screenName.trimmed
        if let last = trimmed.split(separator: ">", omittingEmptySubsequences: true).last {
            return String(last).trimmed
        }
        return trimmed
    }

    private func metadataTile(label: String, value: String, index: Int) -> some View {
        metadataTile(label: label, value: value, accent: metadataAccent(for: index))
    }

    private func metadataTile(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(LColors.primaryText.opacity(0.72))
                .shadow(color: LColors.background.opacity(0.45), radius: 1, x: 0, y: 1)

            Text(value.trimmed.isEmpty ? "Not provided" : value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(value.trimmed.isEmpty ? LColors.primaryText.opacity(0.62) : LColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
        .background {
            BubblyTileSurface(tint: accent, cornerRadius: 18)
        }
        .bubblyTileLift()
    }

    private func metadataAccent(for index: Int) -> Color {
        switch (index / 2) % 3 {
        case 1:
            return LColors.secondaryAccent
        case 2:
            return LColors.indicators
        default:
            return LColors.primaryActions
        }
    }

    private func reportTextSection(title: String, text: String, accent: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            MarklyReportSectionHeader(title: title, color: accent ?? LColors.primaryText)
            GlassCard(cornerRadius: 22) {
                Text(text.trimmed.isEmpty ? "Not provided" : text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(text.trimmed.isEmpty ? LColors.textSecondary : LColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay {
                if let accent {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(accent, lineWidth: 1.2)
                }
            }
        }
    }
}

private struct SubmittedReportAttachmentCard: View {
    let attachment: SubmittedReportAttachment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LColors.raisedSurfaces)

                if let image = UIImage(data: attachment.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipped()
                } else {
                    CustomAssetIcon(name: "image", size: 28, tint: LColors.textSecondary)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LColors.secondaryAccent, lineWidth: 1.2)
            }

            Text(attachment.displayName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .lineLimit(1)
                .frame(width: 96, alignment: .center)
        }
        .padding(8)
        .frame(width: 112, height: 132)
        .background(LColors.surfaces, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LColors.secondaryAccent, lineWidth: 1.2)
        }
    }
}
