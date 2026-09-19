//
//  SharedBookmarkPayload.swift
//  Markly
//

import Foundation

struct SharedBookmarkPayload: Codable {
    var title: String = ""
    var bookmarkDescription: String = ""
    var url: String = ""
    var tagsRaw: String = ""
    var targetFolderSystemKey: String = "inbox"
    var targetFolderName: String = "Inbox"
    var sharedAt: Date = Date()
}
