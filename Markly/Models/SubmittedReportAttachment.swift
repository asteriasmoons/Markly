//
//  SubmittedReportAttachment.swift
//  Markly
//

import Foundation
import SwiftData

@Model
final class SubmittedReportAttachment: Identifiable {
    var id: UUID = UUID()
    var displayName: String = ""
    @Attribute(.externalStorage) var imageData: Data = Data()
    var createdAt: Date = Date()
    var report: SubmittedReport?

    init(
        id: UUID = UUID(),
        displayName: String,
        imageData: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
