//
//  SharedFolderOption.swift
//  Markly
//

import Foundation

struct SharedFolderOption: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var systemKey: String = ""
    var iconName: String = "folder"
}
