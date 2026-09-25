import Foundation

/// Turns mapped corgi geometry into an Image Playground prompt.
///
/// Image Playground takes text concepts plus a source image; it does not take
/// numeric sliders. So the numbers from `CorgiFaceMapper` have to become
/// English. This type owns that translation and is pure and testable.
public enum CorgiPromptBuilder {

    /// Builds the descriptive prompt for a set of corgi features.
    ///
    /// Only traits that are clearly present get mentioned. Describing every
    /// feature on every image produces long prompts where the strong signals
    /// get diluted by neutral ones.
    public static func prompt(for corgi: CorgiFeatures) -> String {
        var phrases: [String] = ["a Pembroke Welsh Corgi"]

        phrases.append(earPhrase(flop: corgi.earFlop, size: corgi.earSize))
        phrases.append(eyePhrase(openness: corgi.eyeOpenness))
        phrases.append(snoutPhrase(length: corgi.snoutLength))

        if corgi.tongueOut {
            phrases.append("mouth open in a happy smile with tongue out")
        } else if corgi.mouthOpenness > 0.5 {
            phrases.append("mouth slightly open")
        } else {
            phrases.append("mouth closed")
        }

        if corgi.cheekFluff > 0.6 {
            phrases.append("thick fluffy cheek fur")
        }

        phrases.append("facing the camera, portrait, friendly expression")
        return phrases.joined(separator: ", ")
    }

    public static func earPhrase(flop: Double, size: Double) -> String {
        let sizeWord = size > 0.55 ? "large " : ""
        if flop < 0.25 {
            return "\(sizeWord)upright pointed ears"
        } else if flop < 0.45 {
            return "\(sizeWord)ears tipped slightly forward"
        } else {
            return "\(sizeWord)soft folded ears"
        }
    }

    public static func eyePhrase(openness: Double) -> String {
        if openness > 0.7 {
            return "wide alert bright eyes"
        } else if openness > 0.4 {
            return "relaxed round eyes"
        } else {
            return "gently squinting eyes"
        }
    }

    public static func snoutPhrase(length: Double) -> String {
        if length > 0.6 {
            return "a long slender snout"
        } else if length > 0.4 {
            return "a medium snout"
        } else {
            return "a short rounded snout"
        }
    }
}
