//
//  BugReportView.swift
//  Markly
//

import PhotosUI
import SwiftData
import SwiftUI

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @State private var title = ""
    @State private var descriptionText = ""
    @State private var expectedBehavior = ""
    @State private var steps = [""]
    @State private var category = "General"
    @State private var severity = "Medium"
    @State private var frequency = "Every Time"
    @State private var additionalNotes = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachmentData: [Data] = []

    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var submittedReportID: String?

    private let categories = MarklyReportFormOptions.areas
    private let severities = ["Low", "Medium", "High", "Critical"]
    private let frequencies = ["Once", "Sometimes", "Often", "Every Time"]

    private var reporterName: String {
        appState.currentUser?.displayName?.trimmed ?? ""
    }

    private var canSubmit: Bool {
        !title.trimmed.isEmpty &&
        !descriptionText.trimmed.isEmpty &&
        steps.contains { !$0.trimmed.isEmpty } &&
        !isSubmitting
    }

    var body: some View {
        MarklyReportFormScaffold(
            eyebrow: nil,
            title: "Report a Bug",
            titleColor: LColors.secondaryAccent,
            closeColor: LColors.secondaryAccent,
            closeIsIconOnly: true
        ) {
            introCard
            reportDetailsSection
            behaviorSection
            reproductionSection
            MarklyReportAttachmentsPicker(
                title: "Attachments",
                selectedPhotos: $selectedPhotos,
                attachmentCount: attachmentData.count,
                accent: LColors.primaryActions
            )
            MarklyReportDiagnosticsCard(
                message: "Markly will include its app version, build number, bundle identifier, device model, iOS version, locale, time zone, and the screen this report came from.",
                borderColor: LColors.secondaryAccent,
                titleColor: LColors.secondaryAccent
            )

            if let submissionError {
                MarklyReportErrorCard(message: submissionError)
            }

            if let submittedReportID {
                MarklyReportSuccessCard(title: "Report Sent", reportID: submittedReportID)
            }

            submitButton
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await loadAttachments(from: newItems) }
        }
    }

    private var introCard: some View {
        MarklyReportIntroCard(
            title: "Send this directly to Voxiverse",
            message: "Describe exactly what happened. Markly will attach the app version, build, device, iOS version, locale, time zone, and submission time automatically.",
            borderColor: LColors.primaryActions,
            titleColor: LColors.primaryActions
        )
    }

    private var reportDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "Report Details", color: LColors.secondaryAccent)
            MarklyReportTextField(title: "Title", placeholder: "Short description of the bug", text: $title, accent: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Area", options: categories, selection: $category, accent: LColors.primaryActions)
            MarklyReportPickerField(title: "Severity", options: severities, selection: $severity, accent: LColors.secondaryAccent)
            MarklyReportPickerField(title: "Frequency", options: frequencies, selection: $frequency, accent: LColors.indicators)
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "What Happened", color: LColors.indicators)
            MarklyReportTextEditor(title: "Description", placeholder: "Tell me what happened, what you were doing, and what went wrong.", text: $descriptionText, minHeight: 150, accent: LColors.indicators)
            MarklyReportTextEditor(title: "Expected Behavior", placeholder: "What did you expect Markly to do instead?", text: $expectedBehavior, minHeight: 110, accent: LColors.primaryActions)
        }
    }

    private var reproductionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarklyReportSectionHeader(title: "Reproduce the Bug", color: LColors.secondaryAccent)
            MarklyReportDynamicStepsField(title: "Steps to Reproduce", steps: $steps, maxSteps: 10, accent: LColors.secondaryAccent)
            MarklyReportTextEditor(title: "Additional Notes", placeholder: "Anything else that might help explain the problem?", text: $additionalNotes, minHeight: 100, accent: LColors.indicators)
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submitReport() }
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(LColors.background)
                } else {
                    CustomAssetIcon(name: "share", size: 17, tint: LColors.background)
                }

                Text(isSubmitting ? "Sending..." : "Submit Bug Report")
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
    private func submitReport() async {
        isSubmitting = true
        submissionError = nil
        submittedReportID = nil

        let payload = VoxiverseBugReportPayload(
            title: title,
            description: descriptionText,
            expectedBehavior: expectedBehavior,
            steps: steps,
            category: category,
            severity: severity,
            frequency: frequency,
            additionalNotes: additionalNotes,
            reporterName: reporterName,
            attachmentData: attachmentData
        )

        do {
            let result = try await VoxiverseBugReportService.shared.submit(payload)
            do {
                try saveSubmittedReport(reportID: result.reportID, diagnostics: result.diagnostics)
                resetForm()
                dismiss()
            } catch {
                submittedReportID = result.reportID
                submissionError = "The report was sent, but its local Submitted copy could not be saved: \(error.localizedDescription)"
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
        descriptionText = ""
        expectedBehavior = ""
        steps = [""]
        category = "General"
        severity = "Medium"
        frequency = "Every Time"
        additionalNotes = ""
        selectedPhotos = []
        attachmentData = []
        submissionError = nil
        submittedReportID = nil
        isSubmitting = false
    }

    @MainActor
    private func saveSubmittedReport(reportID: String, diagnostics: MarklyReportDiagnostics) throws {
        let savedAttachments = attachmentData.prefix(3).enumerated().map { index, data in
            SubmittedReportAttachment(
                displayName: "Screenshot \(index + 1)",
                imageData: data
            )
        }
        let report = SubmittedReport(
            reportID: reportID,
            title: title.trimmed,
            descriptionText: descriptionText.trimmed,
            expectedBehavior: expectedBehavior.trimmed,
            steps: steps.map(\.trimmed).filter { !$0.isEmpty },
            category: category,
            severity: severity,
            frequency: frequency,
            appName: diagnostics.appName,
            appVersion: diagnostics.appVersion,
            buildNumber: diagnostics.buildNumber,
            bundleIdentifier: diagnostics.bundleIdentifier,
            deviceModel: diagnostics.deviceModel,
            iOSVersion: diagnostics.iOSVersion,
            locale: diagnostics.locale,
            timeZone: diagnostics.timeZone,
            screenName: diagnostics.screenName,
            additionalNotes: additionalNotes.trimmed,
            submittedAt: diagnostics.submittedAt,
            attachments: savedAttachments
        )
        modelContext.insert(report)
        try modelContext.save()
    }
}
