//
//  VoxiverseBugReportService.swift
//  Markly
//

import CloudKit
import Foundation

struct VoxiverseBugReportPayload {
    let title: String
    let description: String
    let expectedBehavior: String
    let steps: [String]
    let category: String
    let severity: String
    let frequency: String
    let additionalNotes: String
    let reporterName: String
    let attachmentData: [Data]
}

enum VoxiverseBugReportError: LocalizedError {
    case missingRequiredFields

    var errorDescription: String? {
        switch self {
        case .missingRequiredFields:
            return "Please complete the required fields before submitting."
        }
    }
}

final class VoxiverseBugReportService {
    static let shared = VoxiverseBugReportService()

    static let containerIdentifier = "iCloud.im.lystaria.Voxiverse"

    private let database: CKDatabase

    private init() {
        database = CKContainer(identifier: Self.containerIdentifier).publicCloudDatabase
    }

    @MainActor
    func submit(_ payload: VoxiverseBugReportPayload) async throws -> (reportID: String, diagnostics: MarklyReportDiagnostics) {
        let trimmedTitle = payload.title.trimmed
        let trimmedDescription = payload.description.trimmed
        let cleanedSteps = payload.steps
            .map(\.trimmed)
            .filter { !$0.isEmpty }

        guard !trimmedTitle.isEmpty, !trimmedDescription.isEmpty, !cleanedSteps.isEmpty else {
            throw VoxiverseBugReportError.missingRequiredFields
        }

        let diagnostics = MarklyReportDiagnostics.current(screenName: "Settings > Bug Report")
        let reportID = makeReportID()
        let recordID = CKRecord.ID(recordName: reportID)
        let record = CKRecord(recordType: "Report", recordID: recordID)
        record["reportID"] = reportID as CKRecordValue
        record["appID"] = diagnostics.appID as CKRecordValue
        record["appName"] = diagnostics.appName as CKRecordValue
        record["reporterName"] = reporterName(from: payload.reporterName) as CKRecordValue
        record["reportType"] = "Bug Report" as CKRecordValue
        record["title"] = trimmedTitle as CKRecordValue
        record["descriptionText"] = trimmedDescription as CKRecordValue
        record["expectedBehavior"] = payload.expectedBehavior.trimmed as CKRecordValue
        record["stepsToReproduce"] = cleanedSteps.joined(separator: "\n") as CKRecordValue
        record["category"] = payload.category as CKRecordValue
        record["priority"] = payload.severity as CKRecordValue
        record["frequency"] = payload.frequency as CKRecordValue
        record["status"] = "New" as CKRecordValue
        record["internalNotes"] = payload.additionalNotes.trimmed as CKRecordValue
        applyDiagnostics(diagnostics, to: record)

        let tempURLs = try makeAttachmentFiles(from: payload.attachmentData, reportID: reportID, folderName: "VoxiverseMarklyBugReports")
        defer { tempURLs.forEach { try? FileManager.default.removeItem(at: $0) } }

        for (index, url) in tempURLs.enumerated() {
            record["attachment\(index + 1)"] = CKAsset(fileURL: url)
        }

        _ = try await database.save(record)
        try await addToInbox(recordName: recordID.recordName)
        return (reportID, diagnostics)
    }

    private func makeReportID() -> String {
        "MRK-\(UUID().uuidString.prefix(8).uppercased())"
    }

    private func reporterName(from value: String) -> String {
        let trimmed = value.trimmed
        return trimmed.isEmpty ? "Markly" : trimmed
    }

    private func applyDiagnostics(_ diagnostics: MarklyReportDiagnostics, to record: CKRecord) {
        record["submittedAt"] = diagnostics.submittedAt as CKRecordValue
        record["deviceModel"] = diagnostics.deviceModel as CKRecordValue
        record["iOSVersion"] = diagnostics.iOSVersion as CKRecordValue
        record["appVersion"] = diagnostics.appVersion as CKRecordValue
        record["buildNumber"] = diagnostics.buildNumber as CKRecordValue
        record["bundleIdentifier"] = diagnostics.bundleIdentifier as CKRecordValue
        record["screenName"] = diagnostics.screenName as CKRecordValue
        record["locale"] = diagnostics.locale as CKRecordValue
        record["timeZone"] = diagnostics.timeZone as CKRecordValue
    }

    private func addToInbox(recordName: String) async throws {
        let inboxID = CKRecord.ID(recordName: "VoxiverseReportInbox")
        let inbox: CKRecord

        do {
            inbox = try await database.record(for: inboxID)
        } catch let error as CKError where error.code == .unknownItem {
            inbox = CKRecord(recordType: "ReportInbox", recordID: inboxID)
        }

        var names = inbox["reportRecordNames"] as? [String] ?? []
        if !names.contains(recordName) {
            names.append(recordName)
            inbox["reportRecordNames"] = names as CKRecordValue
            _ = try await database.save(inbox)
        }
    }

    private func makeAttachmentFiles(from dataItems: [Data], reportID: String, folderName: String) throws -> [URL] {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return try dataItems.prefix(3).enumerated().map { index, data in
            let url = directory.appendingPathComponent("\(reportID)-\(index + 1).jpg")
            try data.write(to: url, options: .atomic)
            return url
        }
    }
}
