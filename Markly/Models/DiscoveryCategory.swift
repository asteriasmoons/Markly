import Foundation

/// The ten editorial categories supported by the Word Discovery API.
enum DiscoveryCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case beautifulWords
    case emotionsAndFeelings
    case literaryAndPoetic
    case intellectualAndAcademic
    case expressiveVocabulary
    case historicalAndArchaic
    case natureAndTheWorld
    case mysticalAndPhilosophical
    case scienceAndDiscovery
    case personalityAndBehavior

    var id: String { rawValue }

    /// Human-readable label for category selection and discovery summaries.
    var title: String {
        switch self {
        case .beautifulWords: "Beautiful Words"
        case .emotionsAndFeelings: "Emotions & Feelings"
        case .literaryAndPoetic: "Literary & Poetic"
        case .intellectualAndAcademic: "Intellectual & Academic"
        case .expressiveVocabulary: "Expressive Vocabulary"
        case .historicalAndArchaic: "Historical & Archaic"
        case .natureAndTheWorld: "Nature & The World"
        case .mysticalAndPhilosophical: "Mystical & Philosophical"
        case .scienceAndDiscovery: "Science & Discovery"
        case .personalityAndBehavior: "Personality & Behavior"
        }
    }

    /// Short supporting copy for the category picker.
    var subtitle: String {
        switch self {
        case .beautifulWords: "Elegant, evocative, and lovely language."
        case .emotionsAndFeelings: "Words for the full spectrum of feeling."
        case .literaryAndPoetic: "Language shaped for stories and verse."
        case .intellectualAndAcademic: "Ideas, reasoning, and scholarly expression."
        case .expressiveVocabulary: "Vivid words that make a statement."
        case .historicalAndArchaic: "Forgotten and time-honored expressions."
        case .natureAndTheWorld: "Earth, sky, landscapes, and living things."
        case .mysticalAndPhilosophical: "Wonder, meaning, and the unseen."
        case .scienceAndDiscovery: "The language of inquiry and discovery."
        case .personalityAndBehavior: "Traits, habits, and human nature."
        }
    }
}
