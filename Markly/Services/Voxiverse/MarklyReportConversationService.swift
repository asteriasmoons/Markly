//
//  MarklyReportConversationService.swift
//  Markly
//

import CloudKit
import Combine
import Foundation
import SwiftData

@MainActor
final class MarklyReportConversationService: ObservableObject {
    @Published private(set) var snapshot: MarklyReportConversationSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published private(set) var isUpdatingInvitation = false
    @Published var errorMessage: String?

    private let container: CKContainer

    init(container: CKContainer = CKContainer(identifier: MarklyReportConversationCloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func load(report: SubmittedReport, modelContext: ModelContext, markRead: Bool = false) async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await fetchSnapshot(for: report, modelContext: modelContext, markRead: markRead)
            snapshot = loaded
        } catch {
            snapshot = cachedSnapshot(for: report)
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func accept(report: SubmittedReport, modelContext: ModelContext) async {
        isUpdatingInvitation = true
        errorMessage = nil
        do {
            let current = try await currentSnapshot(for: report, modelContext: modelContext)
            guard let recordID = current.recordID else { throw ConversationError.missingSharedConversation }
            let database = conversationDatabase(for: recordID)
            let root = try await fetchRecord(recordID, in: database)
            let now = Date()
            root[MarklyReportConversationCloudKitSchema.ConversationField.invitationState] = MarklyReportConversationState.accepted.rawValue as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.acceptedAt] = now as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.updatedAt] = now as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.reporterUnreadCount] = 0 as CKRecordValue
            _ = try await database.modifyRecords(saving: [root], deleting: [], savePolicy: .changedKeys, atomically: true)
            try? await updatePublicReportConversationState(for: report, state: .accepted, timestamp: now)

            snapshot = try await fetchSnapshot(for: report, modelContext: modelContext, markRead: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdatingInvitation = false
    }

    func decline(report: SubmittedReport, modelContext: ModelContext) async {
        isUpdatingInvitation = true
        errorMessage = nil
        do {
            let current = try await currentSnapshot(for: report, modelContext: modelContext)
            guard let recordID = current.recordID else { throw ConversationError.missingSharedConversation }
            let database = conversationDatabase(for: recordID)
            let root = try await fetchRecord(recordID, in: database)
            let now = Date()
            root[MarklyReportConversationCloudKitSchema.ConversationField.invitationState] = MarklyReportConversationState.declined.rawValue as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.declinedAt] = now as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.updatedAt] = now as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.reporterUnreadCount] = 0 as CKRecordValue
            _ = try await database.modifyRecords(saving: [root], deleting: [], savePolicy: .changedKeys, atomically: true)
            try? await updatePublicReportConversationState(for: report, state: .declined, timestamp: now)

            snapshot = try await fetchSnapshot(for: report, modelContext: modelContext, markRead: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdatingInvitation = false
    }

    func sendReporterMessage(_ rawText: String, report: SubmittedReport, modelContext: ModelContext) async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !isSending else { return }

        isSending = true
        errorMessage = nil
        do {
            let current = try await currentSnapshot(for: report, modelContext: modelContext)
            guard current.state == .accepted else { throw ConversationError.notAccepted }
            guard let recordID = current.recordID else { throw ConversationError.missingSharedConversation }

            let database = conversationDatabase(for: recordID)
            let root = try await fetchRecord(recordID, in: database)
            guard MarklyReportConversationState(rawValue: root.marklyString(MarklyReportConversationCloudKitSchema.ConversationField.invitationState)) == .accepted else {
                throw ConversationError.notAccepted
            }

            let now = Date()
            let messageID = UUID().uuidString
            let messageRecordID = CKRecord.ID(recordName: "message-\(messageID)", zoneID: root.recordID.zoneID)
            let message = CKRecord(recordType: MarklyReportConversationCloudKitSchema.RecordType.message, recordID: messageRecordID)
            message.parent = CKRecord.Reference(recordID: root.recordID, action: .none)
            message[MarklyReportConversationCloudKitSchema.MessageField.messageID] = messageID as CKRecordValue
            message[MarklyReportConversationCloudKitSchema.MessageField.conversation] = CKRecord.Reference(recordID: root.recordID, action: .none)
            message[MarklyReportConversationCloudKitSchema.MessageField.conversationRecordName] = root.recordID.recordName as CKRecordValue
            message[MarklyReportConversationCloudKitSchema.MessageField.senderRole] = MarklyReportConversationSenderRole.reporter.rawValue as CKRecordValue
            message[MarklyReportConversationCloudKitSchema.MessageField.body] = text as CKRecordValue
            message[MarklyReportConversationCloudKitSchema.MessageField.createdAt] = now as CKRecordValue
            message[MarklyReportConversationCloudKitSchema.MessageField.clientMessageID] = messageID as CKRecordValue

            var names = root[MarklyReportConversationCloudKitSchema.ConversationField.messageRecordNames] as? [String] ?? []
            if !names.contains(messageRecordID.recordName) {
                names.append(messageRecordID.recordName)
            }
            root[MarklyReportConversationCloudKitSchema.ConversationField.messageRecordNames] = names as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.lastMessageAt] = now as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.lastMessageSenderRole] = MarklyReportConversationSenderRole.reporter.rawValue as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.updatedAt] = now as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.staffUnreadCount] = (root.marklyInt(MarklyReportConversationCloudKitSchema.ConversationField.staffUnreadCount) + 1) as CKRecordValue

            _ = try await database.modifyRecords(saving: [root, message], deleting: [], savePolicy: .changedKeys, atomically: true)
            try? await updatePublicReportConversationLastActivity(for: report, state: .accepted, timestamp: now)
            snapshot = try await fetchSnapshot(for: report, modelContext: modelContext, markRead: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func fetchSummary(for report: SubmittedReport, modelContext: ModelContext) async -> MarklyReportConversationSnapshot {
        do {
            return try await fetchSnapshot(for: report, modelContext: modelContext)
        } catch {
            return cachedSnapshot(for: report)
        }
    }

    private func currentSnapshot(for report: SubmittedReport, modelContext: ModelContext) async throws -> MarklyReportConversationSnapshot {
        if let snapshot {
            return snapshot
        }
        return try await fetchSnapshot(for: report, modelContext: modelContext)
    }

    private func fetchSnapshot(
        for report: SubmittedReport,
        modelContext: ModelContext,
        markRead: Bool = false
    ) async throws -> MarklyReportConversationSnapshot {
        let publicRecord = try await fetchPublicReport(for: report)
        applyConversationPointer(from: publicRecord, to: report, modelContext: modelContext)

        guard let shareURL = URL(string: report.conversationShareURL), !report.conversationShareURL.isEmpty else {
            report.conversationState = .notStarted
            report.conversationUnreadCount = 0
            try? modelContext.save()
            return .notStarted(for: report)
        }

        let metadata = try await shareMetadata(for: shareURL)
        try await acceptShareIfNeeded(metadata)

        let resolvedConversation = try await fetchConversationRecord(
            metadata: metadata,
            report: report
        )
        let database = resolvedConversation.database
        let root = resolvedConversation.record
        if markRead {
            let now = Date()
            root[MarklyReportConversationCloudKitSchema.ConversationField.reporterUnreadCount] = 0 as CKRecordValue
            root[MarklyReportConversationCloudKitSchema.ConversationField.reporterLastReadAt] = now as CKRecordValue
            _ = try await database.modifyRecords(saving: [root], deleting: [], savePolicy: .changedKeys, atomically: true)
        }

        let messages = try await fetchMessages(from: root, in: database)
        let snapshot = makeSnapshot(from: root, shareURL: shareURL, messages: messages, fallbackReport: report)
        applySnapshot(snapshot, to: report, modelContext: modelContext)
        try await MarklyReportConversationNotificationManager.registerSharedConversationNotifications(
            database: database,
            zoneID: root.recordID.zoneID
        )
        if snapshot.state == .invited {
            await MarklyReportConversationNotificationManager.notifyInvitationDiscovered(
                reportID: report.reportID,
                reportTitle: report.title
            )
        }
        return snapshot
    }

    private func fetchPublicReport(for report: SubmittedReport) async throws -> CKRecord {
        let database = container.publicCloudDatabase
        return try await fetchRecord(CKRecord.ID(recordName: report.reportID), in: database)
    }

    private func updatePublicReportConversationState(
        for report: SubmittedReport,
        state: MarklyReportConversationState,
        timestamp: Date
    ) async throws {
        let record = try await fetchPublicReport(for: report)
        record[MarklyReportConversationCloudKitSchema.PublicReportField.conversationState] = state.rawValue as CKRecordValue
        record[MarklyReportConversationCloudKitSchema.PublicReportField.conversationUpdatedAt] = timestamp as CKRecordValue
        _ = try await container.publicCloudDatabase.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys, atomically: true)
    }

    private func updatePublicReportConversationLastActivity(
        for report: SubmittedReport,
        state: MarklyReportConversationState,
        timestamp: Date
    ) async throws {
        let record = try await fetchPublicReport(for: report)
        record[MarklyReportConversationCloudKitSchema.PublicReportField.conversationState] = state.rawValue as CKRecordValue
        record[MarklyReportConversationCloudKitSchema.PublicReportField.conversationUpdatedAt] = timestamp as CKRecordValue
        record[MarklyReportConversationCloudKitSchema.PublicReportField.conversationLastMessageAt] = timestamp as CKRecordValue
        _ = try await container.publicCloudDatabase.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys, atomically: true)
    }

    private func applyConversationPointer(from record: CKRecord, to report: SubmittedReport, modelContext: ModelContext) {
        report.conversationRecordName = record.marklyString(MarklyReportConversationCloudKitSchema.PublicReportField.conversationRecordName)
        report.conversationZoneName = record.marklyString(MarklyReportConversationCloudKitSchema.PublicReportField.conversationZoneName)
        report.conversationZoneOwnerName = record.marklyString(MarklyReportConversationCloudKitSchema.PublicReportField.conversationZoneOwnerName)
        report.conversationShareURL = record.marklyString(MarklyReportConversationCloudKitSchema.PublicReportField.conversationShareURL)
        report.conversationUpdatedAt = record.marklyDate(MarklyReportConversationCloudKitSchema.PublicReportField.conversationUpdatedAt)
        report.conversationLastMessageAt = record.marklyDate(MarklyReportConversationCloudKitSchema.PublicReportField.conversationLastMessageAt)
        if let state = MarklyReportConversationState(rawValue: record.marklyString(MarklyReportConversationCloudKitSchema.PublicReportField.conversationState)) {
            report.conversationState = state
        }
        try? modelContext.save()
    }

    private func applySnapshot(_ snapshot: MarklyReportConversationSnapshot, to report: SubmittedReport, modelContext: ModelContext) {
        report.conversationRecordName = snapshot.recordID?.recordName ?? report.conversationRecordName
        report.conversationZoneName = snapshot.recordID?.zoneID.zoneName ?? report.conversationZoneName
        report.conversationZoneOwnerName = snapshot.recordID?.zoneID.ownerName ?? report.conversationZoneOwnerName
        report.conversationShareURL = snapshot.shareURL?.absoluteString ?? report.conversationShareURL
        report.conversationState = snapshot.state
        report.conversationUpdatedAt = snapshot.updatedAt
        report.conversationLastMessageAt = snapshot.messages.last?.createdAt
        report.conversationUnreadCount = snapshot.reporterUnreadCount
        if snapshot.reporterUnreadCount == 0 {
            report.conversationLastReadAt = Date()
        }
        try? modelContext.save()
    }

    private func cachedSnapshot(for report: SubmittedReport) -> MarklyReportConversationSnapshot {
        let recordID: CKRecord.ID?
        if !report.conversationRecordName.isEmpty, !report.conversationZoneName.isEmpty {
            let ownerName = report.conversationZoneOwnerName.isEmpty
                ? CKCurrentUserDefaultName
                : report.conversationZoneOwnerName
            recordID = CKRecord.ID(
                recordName: report.conversationRecordName,
                zoneID: CKRecordZone.ID(
                    zoneName: report.conversationZoneName,
                    ownerName: ownerName
                )
            )
        } else {
            recordID = nil
        }

        return MarklyReportConversationSnapshot(
            id: report.conversationRecordName.isEmpty ? report.reportID : report.conversationRecordName,
            reportID: report.reportID,
            sourceAppID: MarklyReportConversationCloudKitSchema.sourceAppID,
            reportType: report.reportType,
            reportTitle: report.title,
            state: report.conversationState,
            recordID: recordID,
            shareURL: URL(string: report.conversationShareURL),
            createdAt: report.submittedAt,
            updatedAt: report.conversationUpdatedAt,
            invitedAt: report.conversationState == .invited ? report.conversationUpdatedAt : nil,
            acceptedAt: report.conversationState == .accepted ? report.conversationUpdatedAt : nil,
            declinedAt: report.conversationState == .declined ? report.conversationUpdatedAt : nil,
            reporterUnreadCount: report.conversationUnreadCount,
            staffUnreadCount: 0,
            messages: []
        )
    }

    private func shareMetadata(for url: URL) async throws -> CKShare.Metadata {
        let results = try await container.shareMetadatas(for: [url])
        guard let result = results[url] else { throw ConversationError.missingShareMetadata }
        return try result.get()
    }

    private func acceptShareIfNeeded(_ metadata: CKShare.Metadata) async throws {
        guard metadata.participantStatus != .accepted else { return }
        let results = try await container.accept([metadata])
        guard let result = results[metadata] else { throw ConversationError.shareAcceptanceFailed }
        _ = try result.get()
    }

    private func metadataRootRecordID(_ metadata: CKShare.Metadata) -> CKRecord.ID {
        let metadataRecordID: CKRecord.ID
        if #available(iOS 15.0, *) {
            if let recordID = metadata.hierarchicalRootRecordID {
                metadataRecordID = recordID
            } else {
                metadataRecordID = metadata.rootRecordID
            }
        } else {
            metadataRecordID = metadata.rootRecordID
        }
        return metadataRecordID
    }

    private func fetchConversationRecord(
        metadata: CKShare.Metadata,
        report: SubmittedReport
    ) async throws -> (record: CKRecord, database: CKDatabase) {
        let metadataRecordID = metadataRootRecordID(metadata)
        let recordName = report.conversationRecordName.isEmpty
            ? metadataRecordID.recordName
            : report.conversationRecordName
        let zoneName = report.conversationZoneName.isEmpty
            ? metadataRecordID.zoneID.zoneName
            : report.conversationZoneName

        if metadata.participantRole == .owner {
            let privateDatabase = container.privateCloudDatabase
            let privateRecordID = CKRecord.ID(
                recordName: recordName,
                zoneID: CKRecordZone.ID(
                    zoneName: zoneName,
                    ownerName: CKCurrentUserDefaultName
                )
            )
            return (try await fetchRecord(privateRecordID, in: privateDatabase), privateDatabase)
        }

        let sharedDatabase = container.sharedCloudDatabase
        let sharedZones = try await sharedDatabase.allRecordZones()
        let matchingZoneIDs = sharedZones
            .map(\.zoneID)
            .filter { $0.zoneName == zoneName }

        let candidateIDs = matchingZoneIDs.map {
            CKRecord.ID(recordName: recordName, zoneID: $0)
        }
        if !candidateIDs.isEmpty {
            let results = try await sharedDatabase.records(for: candidateIDs)

            for recordID in candidateIDs {
                guard let result = results[recordID] else { continue }
                if case .success(let record) = result {
                    return (record, sharedDatabase)
                }
            }
        }

        // When both apps are signed into the share owner's iCloud account,
        // CloudKit exposes the hierarchy in the private database rather than
        // creating a recipient zone in the shared database.
        let privateDatabase = container.privateCloudDatabase
        let privateRecordID = CKRecord.ID(
            recordName: recordName,
            zoneID: CKRecordZone.ID(
                zoneName: zoneName,
                ownerName: CKCurrentUserDefaultName
            )
        )
        do {
            return (try await fetchRecord(privateRecordID, in: privateDatabase), privateDatabase)
        } catch {
            if matchingZoneIDs.isEmpty {
                throw ConversationError.sharedZoneUnavailable
            }
            throw error
        }
    }

    private func conversationDatabase(for recordID: CKRecord.ID) -> CKDatabase {
        if recordID.zoneID.ownerName == CKCurrentUserDefaultName {
            return container.privateCloudDatabase
        }
        return container.sharedCloudDatabase
    }

    private func fetchRecord(_ recordID: CKRecord.ID, in database: CKDatabase) async throws -> CKRecord {
        let results = try await database.records(for: [recordID])
        guard let result = results[recordID] else { throw ConversationError.recordNotFound }
        return try result.get()
    }

    private func fetchMessages(from root: CKRecord, in database: CKDatabase) async throws -> [MarklyReportConversationMessage] {
        let names = root[MarklyReportConversationCloudKitSchema.ConversationField.messageRecordNames] as? [String] ?? []
        guard !names.isEmpty else { return [] }
        let ids = names.map { CKRecord.ID(recordName: $0, zoneID: root.recordID.zoneID) }
        let results = try await database.records(for: ids)
        return ids.compactMap { id in
            guard let result = results[id], let record = try? result.get() else { return nil }
            return MarklyReportConversationMessage(
                id: record.marklyString(MarklyReportConversationCloudKitSchema.MessageField.messageID, fallback: record.recordID.recordName),
                senderRole: MarklyReportConversationSenderRole(rawValue: record.marklyString(MarklyReportConversationCloudKitSchema.MessageField.senderRole)) ?? .unknown,
                body: record.marklyString(MarklyReportConversationCloudKitSchema.MessageField.body),
                createdAt: record.marklyDate(MarklyReportConversationCloudKitSchema.MessageField.createdAt) ?? record.creationDate ?? Date(),
                creatorRecordName: record.creatorUserRecordID?.recordName ?? ""
            )
        }
        .sorted { $0.createdAt < $1.createdAt }
    }

    private func makeSnapshot(
        from root: CKRecord,
        shareURL: URL,
        messages: [MarklyReportConversationMessage],
        fallbackReport: SubmittedReport
    ) -> MarklyReportConversationSnapshot {
        MarklyReportConversationSnapshot(
            id: root.marklyString(MarklyReportConversationCloudKitSchema.ConversationField.conversationID, fallback: root.recordID.recordName),
            reportID: root.marklyString(MarklyReportConversationCloudKitSchema.ConversationField.reportID, fallback: fallbackReport.reportID),
            sourceAppID: root.marklyString(MarklyReportConversationCloudKitSchema.ConversationField.sourceAppID, fallback: MarklyReportConversationCloudKitSchema.sourceAppID),
            reportType: root.marklyString(MarklyReportConversationCloudKitSchema.ConversationField.reportType, fallback: fallbackReport.reportType),
            reportTitle: root.marklyString(MarklyReportConversationCloudKitSchema.ConversationField.reportTitle, fallback: fallbackReport.title),
            state: MarklyReportConversationState(rawValue: root.marklyString(MarklyReportConversationCloudKitSchema.ConversationField.invitationState)) ?? .notStarted,
            recordID: root.recordID,
            shareURL: shareURL,
            createdAt: root.marklyDate(MarklyReportConversationCloudKitSchema.ConversationField.createdAt) ?? root.creationDate,
            updatedAt: root.marklyDate(MarklyReportConversationCloudKitSchema.ConversationField.updatedAt) ?? root.modificationDate,
            invitedAt: root.marklyDate(MarklyReportConversationCloudKitSchema.ConversationField.invitedAt),
            acceptedAt: root.marklyDate(MarklyReportConversationCloudKitSchema.ConversationField.acceptedAt),
            declinedAt: root.marklyDate(MarklyReportConversationCloudKitSchema.ConversationField.declinedAt),
            reporterUnreadCount: root.marklyInt(MarklyReportConversationCloudKitSchema.ConversationField.reporterUnreadCount),
            staffUnreadCount: root.marklyInt(MarklyReportConversationCloudKitSchema.ConversationField.staffUnreadCount),
            messages: messages
        )
    }

    enum ConversationError: LocalizedError {
        case missingShareMetadata
        case sharedZoneUnavailable
        case shareAcceptanceFailed
        case missingSharedConversation
        case recordNotFound
        case notAccepted

        var errorDescription: String? {
            switch self {
            case .missingShareMetadata:
                return "Markly could not load the private conversation invitation."
            case .sharedZoneUnavailable:
                return "The accepted private conversation is not available in Markly's shared CloudKit database yet."
            case .shareAcceptanceFailed:
                return "Markly could not prepare the private conversation share."
            case .missingSharedConversation:
                return "The private conversation is not available yet."
            case .recordNotFound:
                return "The private conversation record could not be found."
            case .notAccepted:
                return "Accept this invitation before sending a message."
            }
        }
    }
}
