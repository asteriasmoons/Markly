//
//  MarklyActivityType.swift
//  Markly
//

import Foundation

enum MarklyActivityType: String, Codable, CaseIterable {

    case saved
    case opened
    case collectionCreated
    case collectionUpdated
    case bookmarkUpdated
    case bookmarkDeleted
    case bookmarkMoved
    case bookmarkArchived
    case bookmarkPinned
    case imported
    case exported

    var title: String {
        switch self {

        case .saved:
            return "Saved"

        case .opened:
            return "Opened"

        case .collectionCreated:
            return "Collection Created"

        case .collectionUpdated:
            return "Collection Updated"

        case .bookmarkUpdated:
            return "Bookmark Updated"

        case .bookmarkDeleted:
            return "Bookmark Deleted"

        case .bookmarkMoved:
            return "Bookmark Moved"

        case .bookmarkArchived:
            return "Archived"

        case .bookmarkPinned:
            return "Pinned"

        case .imported:
            return "Imported"

        case .exported:
            return "Exported"
        }
    }
}
