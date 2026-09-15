//
//  CustomAssetIcon.swift
//  Markly
//
//  Renders one of the app's custom asset icons. Never uses SF Symbols.
//  If an asset name is missing from the catalog we render a neutral
//  placeholder rather than falling back to Image(systemName:).
//

import SwiftUI

struct CustomAssetIcon: View {
    var name: String
    var size: CGFloat = 22
    var tint: Color? = nil
    var renderingMode: Image.TemplateRenderingMode = .template

    var body: some View {
        Image(name)
            .renderingMode(renderingMode)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint ?? .primary)
    }
}
