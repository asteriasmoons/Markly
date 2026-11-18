import Foundation
import SwiftData

/// Performs legacy duplicate-Inbox cleanup outside the main actor.
@ModelActor
actor InboxRepairWorker {
    func repairIfNeeded() {
        do {
            let folders = try modelContext.fetch(FetchDescriptor<BookmarkFolder>())
            let inboxes = folders.filter { $0.systemKey == "inbox" }

            // No duplicates means no mutation, save, or shared-folder export.
            guard inboxes.count > 1,
                  let canonicalInbox = inboxes.min(by: { $0.createdAt < $1.createdAt }) else {
                return
            }

            let bookmarks = try modelContext.fetch(FetchDescriptor<BookmarkItem>())
            canonicalInbox.name = "Inbox"
            canonicalInbox.iconName = "inboxfill"
            canonicalInbox.sortOrder = 0

            for duplicate in inboxes where duplicate.persistentModelID != canonicalInbox.persistentModelID {
                for bookmark in bookmarks where bookmark.folder?.persistentModelID == duplicate.persistentModelID {
                    bookmark.folder = canonicalInbox
                    bookmark.updatedAt = Date()
                }
                modelContext.delete(duplicate)
            }

            canonicalInbox.updatedAt = Date()
            try modelContext.save()
            SharedFolderExportManager.exportFolders(modelContext: modelContext)
        } catch {
            print("Failed to repair duplicate Inbox folders: \(error)")
        }
    }
}
