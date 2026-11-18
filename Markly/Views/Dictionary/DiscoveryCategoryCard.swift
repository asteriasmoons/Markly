import SwiftUI

/// A compact category tile styled after Markly's Metadata tiles.
struct DiscoveryCategoryCard: View {
    let category: DiscoveryCategory
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(category.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(category.subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(height: 150)
            .background {
                BubblyTileSurface(tint: tint, cornerRadius: 18)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Color.white : .clear, lineWidth: 2)
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title). \(category.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
