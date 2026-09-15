//
//  VoxiverseFeatureRequestService.swift
//  Markly
//

import CloudKit
import Foundation

struct VoxiverseFeatureRequestPayload {
    let featureTitle: String
    let area: String
    let featureType: String
    let importance: String
    let intendedAudience: String
    let featureDescription: String
    let imaginedWorkflow: String
    let desiredLocation: String
    let relatedExistingFeature: String
    let problemAddressed: String
    let desiredResult: String
    let requiresSavedData: String
    let needsNotifications: String
    let needsSharing: String
    let needsAI: String
    let additionalDetails: String
    let reporterName: String
    let attachmentData: [Data]
}

enum VoxiverseFeatureRequestError: LocalizedError {
    case missingRequiredFields

    var errorDescription: String? {
        switch self {
        case .missingRequiredFields:
            return "Please complete the required fields before submitting."
        }
    }
}

final class VoxiverseFeatureRequestService {
    static let shared = VoxiverseFeatureRequestService()

    private let database: CKDatabase

    private init() {
        database = CKContainer(identifier: VoxiverseBugReportService.containerIdentifier).publicCloudDatabase
    }

    @MainActor
    func submit(_ payload: VoxiverseFeatureRequestPayload) async throws -> (reportID: String, diagnostics: MarklyReportDiagnostics) {
        let trimmedTitle = payload.featureTitle.trimmed
        let trimmedArea = payload.area.trimmed
        let trimmedFeatureType = payload.featureType.trimmed
        let trimmedImportance = payload.importance.trimmed
        let trimmedAudience = payload.intendedAudience.trimmed
        let trimmedDescription = payload.featureDescription.trimmed
        let trimmedWorkflow = payload.imaginedWorkflow.trimmed
        let trimmedLocation = payload.desiredLocation.trimmed
        let trimmedProblem = payload.problemAddressed.trimmed
        let trimmedResult = payload.desiredResult.trimmed
        let trimmedSavedData = payload.requiresSavedData.trimmed
        let trimmedNotifications = payload.needsNotifications.trimmed
        let trimmedSharing = payload.needsSharing.trimmed
        let trimmedAI = payload.needsAI.trimmed

        guard !trimmedTitle.isEmpty,
              !trimmedArea.isEmpty,
              !trimmedFeatureType.isEmpty,
              !trimmedImportance.isEmpty,
              !trimmedAudience.isEmpty,
              !trimmedDescription.isEmpty,
              !trimmedWorkflow.isEmpty,
              !trimmedLocation.isEmpty,
              !trimmedProblem.isEmpty,
              !trimmedResult.isEmpty,
              !trimmedSavedData.isEmpty,
              !trimmedNotifications.isEmpty,
              !trimmedSharing.isEmpty,
              !trimmedAI.isEmpty else {
            throw VoxiverseFeatureRequestError.missingRequiredFields
        }

        let diagnostics = MarklyReportDiagnostics.current(screenName: "Settings > Feature Request")
        let reportID = makeReportID()
        let submittedAt = diagnostics.submittedAt
        let recordID = CKRecord.ID(recordName: reportID)
        let record = CKRecord(recordType: "Report", recordID: recordID)
        record["reportID"] = reportID as CKRecordValue
        record["requestID"] = reportID as CKRecordValue
        record["appID"] = diagnostics.appID as CKRecordValue
        record["appName"] = diagnostics.appName as CKRecordValue
        record["reporterName"] = reporterName(from: payload.reporterName) as CKRecordValue
        record["reportType"] = "Feature Request" as CKRecordValue
        record["title"] = trimmedTitle as CKRecordValue
        record["category"] = trimmedArea as CKRecordValue
        record["status"] = "New" as CKRecordValue
        record["submittedAt"] = submittedAt as CKRecordValue
        record["createdAt"] = submittedAt as CKRecordValue
        record["updatedAt"] = submittedAt as CKRecordValue
        record["requestCount"] = 1 as CKRecordValue
        record["descriptionText"] = trimmedDescription as CKRecordValue
        record["featureType"] = trimmedFeatureType as CKRecordValue
        record["importance"] = trimmedImportance as CKRecordValue
        record["intendedAudience"] = trimmedAudience as CKRecordValue
        record["featureDescription"] = trimmedDescription as CKRecordValue
        record["imaginedWorkflow"] = trimmedWorkflow as CKRecordValue
        record["desiredLocation"] = trimmedLocation as CKRecordValue
        record["relatedExistingFeature"] = payload.relatedExistingFeature.trimmed as CKRecordValue
        record["problemAddressed"] = trimmedProblem as CKRecordValue
        record["desiredResult"] = trimmedResult as CKRecordValue
        record["requiresSavedData"] = trimmedSavedData as CKRecordValue
        record["needsNotifications"] = trimmedNotifications as CKRecordValue
        record["needsSharing"] = trimmedSharing as CKRecordValue
        record["needsAI"] = trimmedAI as CKRecordValue
        record["additionalDetails"] = payload.additionalDetails.trimmed as CKRecordValue
        record["internalNotes"] = payload.additionalDetails.trimmed as CKRecordValue
        applyDiagnostics(diagnostics, to: record)

        let tempURLs = try makeAttachmentFiles(from: payload.attachmentData, reportID: reportID, folderName: "VoxiverseMarklyFeatureRequests")
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
