import Foundation

/// The three vocabulary difficulty levels supported by the Word Discovery API.
enum DiscoveryDifficulty: String, CaseIterable, Identifiable, Codable, Hashable {
    case accessible
    case elevated
    case exceptional

    var id: String { rawValue }

    /// Human-readable label for the discovery difficulty picker.
    var title: String {
        switch self {
        case .accessible: "Accessible"
        case .elevated: "Elevated"
        case .exceptional: "Exceptional"
        }
    }

    /// Brief explanation of the vocabulary complexity at each level.
    var subtitle: String {
        switch self {
        case .accessible:
            "Approachable words with interesting meanings and everyday uses."
        case .elevated:
            "Sophisticated, nuanced vocabulary to deepen your expression."
        case .exceptional:
            "Rare, remarkable words with precise and distinctive meanings."
        }
    }
}
