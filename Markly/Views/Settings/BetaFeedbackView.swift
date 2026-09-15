//
//  BetaFeedbackView.swift
//  Markly
//

import PhotosUI
import SwiftData
import SwiftUI

struct BetaFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @State private var title = ""
    @State private var area = "General"
    @State private var overallExperience = "Good"
    @State private var testedWhat = ""
    @State private var workedWell = ""
    @State private var couldBeBetter = ""
    @State private var unexpected = ""
    @State private var additionalThoughts = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachmentData: [Data] = []

    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var submittedReportID: String?

    private let areas = MarklyReportFormOptions.areas
    private let overallExperiences = ["Excellent", "Good", "Okay", "Poor"]

    private var reporterName: String {
        appState.currentUser?.displayName?.trimmed ?? ""
    }

    private var canSubmit: Bool {
        !title.trimmed.isEmpty &&
        !area.trimmed.isEmpty &&
        !overallExperience.trimmed.isEmpty &&
        !testedWhat.trimmed.isEmpty &&
        !isSubmitting
    }

    var body: some View {
        MarklyReportFormScaffold(
            eyebrow: nil,
            title: "Beta Feedback",
            titleColor: LColors.secondaryAccent,
            closeColor: LColors.secondaryAccent,
            closeIsIconOnly: true
        ) {
            introCard
            feedbackDetailsSection
            testingSection
            MarklyReportAttachmentsPicker(
                title: "Attachments",
                selectedPhotos: $selectedPhotos,
                attachmentCount: attachmentData.count,
                accent: LColors.primaryActions
            )
            MarklyReportDiagnosticsCard(
                message: "Markly will include its app version, build number, bundle identifier, device model, iOS version, locale, time zone, and submission time.",
                borderColor: LColors.secondaryAccent,
                titleColor: LColors.secondaryAccent
            )

            if let submissionError {
                MarklyReportErrorCard(message: submissionError)
            }

            if let submittedReportID {
                MarklyReportSuccessCard(title: "Feedback Sent", reportID: submittedReportID)
            }

            submitButton
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await loadAttachments(from: newItems) }
        }
    }

    private var introCard: some View {
        MarklyReportIntroCard(
            title: "Send beta feedback to Voxiverse",
            message: "Share what you tested, what worked, and what needs improvement. Markly will attach the same automatic diagnostics used for reports.",
            borderColor: LColors.primaryActions,
            titleColor: LColors.primaryActions
        )
    }

    private var feedbackDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "Feedback Details", color: LColors.secondaryAccent)
            MarklyReportTextField(title: "Title", placeholder: "Short summary of the feedback", text: $title, accent: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Area", options: areas, selection: $area, accent: LColors.primaryActions)
            MarklyReportPickerField(title: "Overall Experience", options: overallExperiences, selection: $overallExperience, accent: LColors.secondaryAccent)
        }
    }

    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "Testing Notes", color: LColors.indicators)
            MarklyReportTextEditor(
                title: "What Did You Test?",
                placeholder: "Which feature, workflow, screen, or part of Markly were you testing?",
                text: $testedWhat,
                minHeight: 130,
                accent: LColors.indicators
            )
            MarklyReportTextEditor(
                title: "What Worked Well?",
                placeholder: "What felt good, clear, useful, or polished?",
                text: $workedWell,
                minHeight: 110,
                accent: LColors.primaryActions
            )
            MarklyReportTextEditor(
                title: "What Could Be Better?",
                placeholder: "What felt awkward, confusing, incomplete, slow, or visually off?",
                text: $couldBeBetter,
                minHeight: 110,
                accent: LColors.secondaryAccent
            )
            MarklyReportTextEditor(
                title: "Anything Unexpected?",
                placeholder: "Anything surprising that was not necessarily a bug?",
                text: $unexpected,
                minHeight: 100,
                accent: LColors.indicators
            )
            MarklyReportTextEditor(
                title: "Additional Thoughts",
                placeholder: "Anything else you want to share?",
                text: $additionalThoughts,
                minHeight: 100,
                accent: LColors.primaryActions
            )
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submitFeedback() }
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(LColors.background)
                } else {
                    CustomAssetIcon(name: "share", size: 17, tint: LColors.background)
                }

                Text(isSubmitting ? "Sending..." : "Submit Beta Feedback")
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
    private func submitFeedback() async {
        isSubmitting = true
        submissionError = nil
        submittedReportID = nil

        let payload = VoxiverseBetaFeedbackPayload(
            title: title,
            area: area,
            overallExperience: overallExperience,
            testedWhat: testedWhat,
            workedWell: workedWell,
            couldBeBetter: couldBeBetter,
            unexpected: unexpected,
            additionalThoughts: additionalThoughts,
            reporterName: reporterName,
            attachmentData: attachmentData
        )

        do {
            let result = try await VoxiverseBetaFeedbackService.shared.submit(payload)
            do {
                try saveSubmittedFeedback(reportID: result.reportID, diagnostics: result.diagnostics)
                resetForm()
                dismiss()
            } catch {
                submittedReportID = result.reportID
                submissionError = "The feedback was sent, but its local Submitted copy could not be saved: \(error.localizedDescription)"
                isSubmitting = false
            }
        } catch {
            submissionError = error.localizedDescription
            isSubmitting = false
        }
    }

    @MainActor
    private func resetForm() {
        title = ""
        area = "General"
        overallExperience = "Good"
        testedWhat = ""
        workedWell = ""
        couldBeBetter = ""
        unexpected = ""
        additionalThoughts = ""
        selectedPhotos = []
        attachmentData = []
        submissionError = nil
        submittedReportID = nil
        isSubmitting = false
    }

    @MainActor
    private func saveSubmittedFeedback(reportID: String, diagnostics: MarklyReportDiagnostics) throws {
        let savedAttachments = attachmentData.prefix(3).enumerated().map { index, data in
            SubmittedReportAttachment(
                displayName: "Screenshot \(index + 1)",
                imageData: data
            )
        }
        let report = SubmittedReport(
            reportID: reportID,
            reportType: "Beta Feedback",
            title: title.trimmed,
            descriptionText: testedWhat.trimmed,
            expectedBehavior: "",
            steps: [],
            category: area,
            severity: "",
            frequency: "",
            overallExperience: overallExperience,
            testedWhat: testedWhat.trimmed,
            workedWell: workedWell.trimmed,
            couldBeBetter: couldBeBetter.trimmed,
            unexpected: unexpected.trimmed,
            appName: diagnostics.appName,
            appVersion: diagnostics.appVersion,
            buildNumber: diagnostics.buildNumber,
            bundleIdentifier: diagnostics.bundleIdentifier,
            deviceModel: diagnostics.deviceModel,
            iOSVersion: diagnostics.iOSVersion,
            locale: diagnostics.locale,
            timeZone: diagnostics.timeZone,
            screenName: diagnostics.screenName,
            additionalNotes: additionalThoughts.trimmed,
            submittedAt: diagnostics.submittedAt,
            attachments: savedAttachments
        )
        modelContext.insert(report)
        try modelContext.save()
    }
}
