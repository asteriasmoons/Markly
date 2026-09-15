//
//  CustomChevronButton.swift
//  Markly
//
//  The app's custom chevron buttons. Always uses the `chevleft` /
//  `chevright` / `chevup` / `chevdown` custom assets in the catalog.
//  Never substitutes SF Symbols.
//

import SwiftUI

enum ChevronDirection {
    case left, right, up, down

    var assetName: String {
        switch self {
        case .left:  return "chevleft"
        case .right: return "chevright"
        case .up:    return "chevup"
        case .down:  return "chevdown"
        }
    }
}

struct CustomChevronButton: View {
    @Environment(\.appTheme) private var theme
    var direction: ChevronDirection
    var size: CGFloat = 18
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            CustomAssetIcon(
                name: direction.assetName,
                size: size,
                tint: theme.palette.textPrimary
            )
            .padding(10)
            .background {
                if #available(iOS 26.0, *) {
                    Circle()
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: Circle())
                } else {
                    Circle().fill(theme.palette.surface)
                }
            }
            .overlay {
                Circle().strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}
