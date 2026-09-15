//
//  ReaderSettings.swift
//  Markly
//

import SwiftUI

enum ReaderTextSize: String, CaseIterable, Identifiable {
    case small
    case normal
    case large
    case extraLarge

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small:
            return "Small"
        case .normal:
            return "Default"
        case .large:
            return "Large"
        case .extraLarge:
            return "Extra Large"
        }
    }

    var bodySize: CGFloat {
        switch self {
        case .small:
            return 15
        case .normal:
            return 17
        case .large:
            return 20
        case .extraLarge:
            return 23
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .small:
            return 5
        case .normal:
            return 7
        case .large:
            return 8
        case .extraLarge:
            return 10
        }
    }

    func headingSize(for level: Int) -> CGFloat {
        let base: CGFloat

        switch min(max(level, 1), 6) {
        case 1:
            base = bodySize + 13
        case 2:
            base = bodySize + 9
        case 3:
            base = bodySize + 6
        case 4:
            base = bodySize + 4
        default:
            base = bodySize + 2
        }

        return base
    }
}

