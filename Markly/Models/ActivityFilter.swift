//
//  ActivityFilter.swift
//  Markly
//

import Foundation

enum ActivityFilter: String, CaseIterable, Identifiable {

    case all
    case saved
    case opened
    case collections
    case bookmarks
    case imported
    case exported

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}
