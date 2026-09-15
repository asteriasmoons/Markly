//
//  ActivityStat.swift
//  Markly
//

import Foundation

struct ActivityStat: Identifiable {

    let id = UUID()

    let title: String
    let value: Int

    let icon: String
    let isCustomIcon: Bool
}
