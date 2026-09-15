//
//  FeatureRequestView.swift
//  Markly
//

import PhotosUI
import SwiftData
import SwiftUI

struct FeatureRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @State private var featureTitle = ""
    @State private var area = "General"
    @State private var featureType = "New Feature"
    @State private var importance = "Useful"
    @State private var intendedAudience = "Everyone"
    @State private var featureDescription = ""
    @State private var imaginedWorkflow = ""
    @State private var desiredLocation = "Existing Area"
    @State private var relatedExistingFeature = "None"
    @State private var problemAddressed = ""
    @State private var desiredResult = ""
    @State private var requiresSavedData = "Unsure"
    @State private var needsNotifications = "Unsure"
    @State private var needsSharing = "Unsure"
    @State private var needsAI = "Unsure"
    @State private var additionalDetails = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachmentData: [Data] = []

    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var submittedReportID: String?

    private let areas = MarklyReportFormOptions.areas

    private let featureTypes = [
        "New Feature", "Enhancement to Existing Feature", "New Tool",
        "New View or Screen", "New Integration", "Automation",
        "Customization Option", "Accessibility", "Import / Export",
        "Widget", "Share Extension", "Other"
    ]

    private let importanceOptions = ["Nice to Have", "Useful", "Important", "Essential"]

    private let audienceOptions = [
        "Everyone", "Heavy Readers", "Research / Study", "Writers",
        "Bookmark Collectors", "Shared Folder Users", "Accessibility Need", "Other"
    ]

    private let locationOptions = ["Existing Area", "New Screen", "Library", "Reader", "Pins", "Activity", "Settings", "Share Extension", "App-Wide", "Unsure"]

    private let relatedFeatureOptions = [
        "None", "Library", "Bookmarks", "Bookmark Detail", "Bookmark Editor",
        "Bookmark Preview", "Bookmark Notes", "Folders", "Folder Detail",
        "Tags", "Search", "Favorites", "Archive", "Pinned Items", "Pins",
        "Collections", "Pin Collections", "Reader", "Reader Settings",
        "Reader Toolbar", "Original View", "Notes", "Activity",
        "Activity Filters", "Activity Stats", "Import / Export",
        "Cloud Sync", "Shared Folders", "Share Extension", "Settings", "Other"
    ]

    private let yesNoUnsureOptions = ["Yes", "No", "Unsure"]
    private let yesNoOptionalUnsureOptions = ["Yes", "No", "Optional", "Unsure"]

    private var reporterName: String {
        appState.currentUser?.displayName?.trimmed ?? ""
    }

    private var canSubmit: Bool {
        !featureTitle.trimmed.isEmpty &&
        !area.trimmed.isEmpty &&
        !featureType.trimmed.isEmpty &&
        !importance.trimmed.isEmpty &&
        !intendedAudience.trimmed.isEmpty &&
        !featureDescription.trimmed.isEmpty &&
        !imaginedWorkflow.trimmed.isEmpty &&
        !desiredLocation.trimmed.isEmpty &&
        !problemAddressed.trimmed.isEmpty &&
        !desiredResult.trimmed.isEmpty &&
        !requiresSavedData.trimmed.isEmpty &&
        !needsNotifications.trimmed.isEmpty &&
        !needsSharing.trimmed.isEmpty &&
        !needsAI.trimmed.isEmpty &&
        !isSubmitting
    }

    var body: some View {
        MarklyReportFormScaffold(
            eyebrow: nil,
            title: "Feature Request",
            titleColor: LColors.secondaryAccent,
            closeColor: LColors.secondaryAccent,
            closeIsIconOnly: true
        ) {
            introCard
            featureDetailsSection
            featureProposalSection
            requirementsSection
            MarklyReportAttachmentsPicker(
                title: "Reference Images",
                selectedPhotos: $selectedPhotos,
                attachmentCount: attachmentData.count,
                accent: LColors.primaryActions
            )
            MarklyReportDiagnosticsCard(
                message: "Markly will include its app version, build number, device model, iOS version, screen, and submission time.",
                borderColor: LColors.secondaryAccent,
                titleColor: LColors.secondaryAccent
            )

            if let submissionError {
                MarklyReportErrorCard(message: submissionError)
            }

            if let submittedReportID {
                MarklyReportSuccessCard(title: "Feature Request Sent", reportID: submittedReportID)
            }

            submitButton
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await loadAttachments(from: newItems) }
        }
    }

    private var introCard: some View {
        MarklyReportIntroCard(
            title: "Send a feature request to Voxiverse",
            message: "Describe the feature, where it should live, how it should work, and what it would make possible in Markly.",
            borderColor: LColors.primaryActions,
            titleColor: LColors.primaryActions
        )
    }

    private var featureDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "Feature Details", color: LColors.secondaryAccent)
            MarklyReportTextField(title: "Feature Title", placeholder: "Short clear name for the feature", text: $featureTitle, accent: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Area", options: areas, selection: $area, accent: LColors.primaryActions)
            MarklyReportPickerField(title: "Feature Type", options: featureTypes, selection: $featureType, accent: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Importance", options: importanceOptions, selection: $importance, accent: LColors.indicators)
            MarklyReportPickerField(title: "Who Is This For?", options: audienceOptions, selection: $intendedAudience, accent: LColors.primaryActions)
        }
    }

    private var featureProposalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "Feature Proposal", color: LColors.indicators)
            MarklyReportTextEditor(
                title: "What Should the Feature Do?",
                placeholder: "Describe the actual capability you want added and what you should be able to accomplish with it.",
                text: $featureDescription,
                minHeight: 130,
                accent: LColors.indicators
            )
            MarklyReportTextEditor(
                title: "How Should It Work?",
                placeholder: "Describe how you imagine using the feature from beginning to end, including what you would tap, enter, select, create, or receive.",
                text: $imaginedWorkflow,
                minHeight: 130,
                accent: LColors.primaryActions
            )
            MarklyReportPickerField(title: "Where Should It Live?", options: locationOptions, selection: $desiredLocation, accent: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Related Existing Feature", options: relatedFeatureOptions, selection: $relatedExistingFeature, accent: LColors.indicators)
            MarklyReportTextEditor(
                title: "What Problem or Limitation Does It Address?",
                placeholder: "Explain what you currently cannot do, what feels limited, or what this feature would make easier or better.",
                text: $problemAddressed,
                minHeight: 130,
                accent: LColors.primaryActions
            )
            MarklyReportTextEditor(
                title: "Desired Result",
                placeholder: "Describe what should exist, happen, or become possible after successfully using the feature.",
                text: $desiredResult,
                minHeight: 120,
                accent: LColors.secondaryAccent
            )
        }
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "Requirements", color: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Would This Require Saved Data?", options: yesNoUnsureOptions, selection: $requiresSavedData, accent: LColors.primaryActions)
            MarklyReportPickerField(title: "Would This Need Notifications?", options: yesNoOptionalUnsureOptions, selection: $needsNotifications, accent: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Would This Need Sharing?", options: yesNoOptionalUnsureOptions, selection: $needsSharing, accent: LColors.indicators)
            MarklyReportPickerField(title: "Would This Need AI?", options: yesNoOptionalUnsureOptions, selection: $needsAI, accent: LColors.primaryActions)
            MarklyReportTextEditor(
                title: "Additional Details",
                placeholder: "Add anything else that would help explain the request.",
                text: $additionalDetails,
                minHeight: 100,
                accent: LColors.indicators
            )
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submitFeatureRequest() }
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(LColors.background)
                } else {
                    CustomAssetIcon(name: "share", size: 17, tint: LColors.background)
                }

                Text(isSubmitting ? "Sending..." : "Submit Feature Request")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .foregroundStyle(LColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                BubblyTileSurface(tint: LColors.indicators, cornerRadius: LSpacing.buttonRadius)
            )
            .bubblyTileLift()
            .opacity(canSubmit ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func loadAttachments(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items.prefix(3) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        await MainActor.run { attachmentData = loaded }
    }

    @MainActor
    private func submitFeatureRequest() async {
        isSubmitting = true
        submissionError = nil
        submittedReportID = nil

        let payload = VoxiverseFeatureRequestPayload(
            featureTitle: featureTitle,
            area: area,
            featureType: featureType,
            importance: importance,
            intendedAudience: intendedAudience,
            featureDescription: featureDescription,
            imaginedWorkflow: imaginedWorkflow,
            desiredLocation: desiredLocation,
            relatedExistingFeature: relatedExistingFeature == "None" ? "" : relatedExistingFeature,
            problemAddressed: problemAddressed,
            desiredResult: desiredResult,
            requiresSavedData: requiresSavedData,
            needsNotifications: needsNotifications,
            needsSharing: needsSharing,
            needsAI: needsAI,
            additionalDetails: additionalDetails,
            reporterName: reporterName,
            attachmentData: attachmentData
        )

        do {
            let result = try await VoxiverseFeatureRequestService.shared.submit(payload)
            do {
                try saveSubmittedFeatureRequest(reportID: result.reportID, diagnostics: result.diagnostics)
                resetForm()
                dismiss()
            } catch {
                submittedReportID = result.reportID
                submissionError = "The feature request was sent, but its local Submitted copy could not be saved: \(error.localizedDescription)"
                isSubmitting = false
            }
        } catch {
            submissionError = error.localizedDescription
            isSubmitting = false
        }
    }

    @MainActor
    private func resetForm() {
        featureTitle = ""
        area = "General"
        featureType = "New Feature"
        importance = "Useful"
        intendedAudience = "Everyone"
        featureDescription = ""
        imaginedWorkflow = ""
        desiredLocation = "Existing Area"
        relatedExistingFeature = "None"
        problemAddressed = ""
        desiredResult = ""
        requiresSavedData = "Unsure"
        needsNotifications = "Unsure"
        needsSharing = "Unsure"
        needsAI = "Unsure"
        additionalDetails = ""
        selectedPhotos = []
        attachmentData = []
        submissionError = nil
        submittedReportID = nil
        isSubmitting = false
    }

    @MainActor
    private func saveSubmittedFeatureRequest(reportID: String, diagnostics: MarklyReportDiagnostics) throws {
        let trimmedTitle = featureTitle.trimmed
        let trimmedDescription = featureDescription.trimmed
        let trimmedWorkflow = imaginedWorkflow.trimmed
        let trimmedProblem = problemAddressed.trimmed
        let trimmedResult = desiredResult.trimmed
        let trimmedAdditionalDetails = additionalDetails.trimmed
        let savedAttachments = attachmentData.prefix(3).enumerated().map { index, data in
            SubmittedReportAttachment(
                displayName: "Reference Image \(index + 1)",
                imageData: data
            )
        }
        let report = SubmittedReport(
            reportID: reportID,
            reportType: "Feature Request",
            title: trimmedTitle,
            descriptionText: trimmedDescription,
            expectedBehavior: "",
            steps: [],
            category: area,
            severity: "",
            frequency: "",
            featureType: featureType,
            featureImportance: importance,
            intendedAudience: intendedAudience,
            featureDescription: trimmedDescription,
            imaginedWorkflow: trimmedWorkflow,
            desiredLocation: desiredLocation,
            relatedExistingFeature: relatedExistingFeature == "None" ? "" : relatedExistingFeature,
            problemAddressed: trimmedProblem,
            desiredResult: trimmedResult,
            requiresSavedData: requiresSavedData,
            needsNotifications: needsNotifications,
            needsSharing: needsSharing,
            needsAI: needsAI,
            additionalDetails: trimmedAdditionalDetails,
            appName: diagnostics.appName,
            appVersion: diagnostics.appVersion,
            buildNumber: diagnostics.buildNumber,
            bundleIdentifier: diagnostics.bundleIdentifier,
            deviceModel: diagnostics.deviceModel,
            iOSVersion: diagnostics.iOSVersion,
            locale: diagnostics.locale,
            timeZone: diagnostics.timeZone,
            screenName: diagnostics.screenName,
            additionalNotes: trimmedAdditionalDetails,
            submittedAt: diagnostics.submittedAt,
            attachments: savedAttachments
        )
        modelContext.insert(report)
        try modelContext.save()
    }
}
