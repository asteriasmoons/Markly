//
//  MarklyActivity.swift
//  Markly
//

import Foundation
import SwiftData

@Model
final class MarklyActivity {

    var id: UUID = UUID()
    var title: String = ""
    var subtitle: String = ""
    var icon: String = "bookedmark"

    /// true = asset catalog icon
    var isCustomIcon: Bool = true

    var timestamp: Date = Date()

    var typeRawValue: String = MarklyActivityType.saved.rawValue

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        icon: String,
        isCustomIcon: Bool = true,
        timestamp: Date = .now,
        type: MarklyActivityType
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isCustomIcon = isCustomIcon
        self.timestamp = timestamp
        self.typeRawValue = type.rawValue
    }

    var type: MarklyActivityType {
        get {
            MarklyActivityType(rawValue: typeRawValue) ?? .saved
        }
        set {
            typeRawValue = newValue.rawValue
        }
    }
}
