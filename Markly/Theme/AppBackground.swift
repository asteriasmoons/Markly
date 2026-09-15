//
//  AppBackground.swift
//  Markly
//
//  Solid page backdrop — the `background` role only. No gradients.
//

import SwiftUI

struct AppBackground: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        theme.palette.background
            .ignoresSafeArea()
    }
}
