import SwiftUI

/// Difficulty selection with Markly's own custom dropdown.
struct DiscoveryDifficultyPicker: View {
    @Binding var selection: DiscoveryDifficulty?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            CustomDropdown(
                title: "Difficulty Level",
                options: DiscoveryDifficulty.allCases,
                labelFor: { $0.title },
                accent: LColors.secondaryAccent,
                showsDividers: true,
                emphasizedStyle: true,
                selection: $selection
            )

            if let selection {
                Text(selection.subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
