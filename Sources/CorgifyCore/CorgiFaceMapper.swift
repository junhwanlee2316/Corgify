import Foundation

/// Maps human facial geometry onto corgi facial geometry.
///
/// This is the core of the app and is deliberately pure, synchronous, and
/// dependency-free so it can be unit tested without a device, a camera, or
/// Apple Intelligence. Everything platform-specific lives elsewhere.
///
/// ## Design
///
/// Each human feature drives a corgi feature through an explicit, documented
/// correspondence rather than an opaque learned mapping:
///
/// | Human              | Corgi          | Rationale                          |
/// |--------------------|----------------|------------------------------------|
/// | eyebrow thickness  | ear flop       | Brows frame human expression the   |
/// |                    |                | way ears frame a dog's.            |
/// | face aspect ratio  | snout length   | Long faces read as long snouts.    |
/// | eye spacing        | eye spacing    | Direct correspondence.             |
/// | eye openness       | eye openness   | Direct correspondence.             |
/// | nose width         | snout width    | Direct correspondence.             |
/// | smile curve        | mouth + tongue | Corgi smiles are open-mouthed.     |
/// | face width         | cheek fluff    | Wide faces get a fuller ruff.      |
/// | roll / yaw         | head pose      | Carried through so the corgi faces |
/// |                    |                | the same way the person did.       |
public enum CorgiFaceMapper {

    /// Human measurement ranges used for normalization.
    ///
    /// These come from the observed spread of Vision landmark output across
    /// typical portrait photos, not from a formal anthropometric study.
    /// Treat them as tunable constants.
    public enum HumanRange {
        public static let aspectRatio: ClosedRange<Double> = 0.60...0.95
        public static let eyeSpacing: ClosedRange<Double> = 0.30...0.55
        public static let eyeOpenness: ClosedRange<Double> = 0.10...0.45
        public static let noseWidth: ClosedRange<Double> = 0.15...0.35
        public static let mouthWidth: ClosedRange<Double> = 0.25...0.55
        public static let browThickness: ClosedRange<Double> = 0.35...0.75
        public static let smileCurve: ClosedRange<Double> = -0.50...1.00
    }

    /// Corgi output ranges. Narrower than the human ranges on purpose: a corgi
    /// with a human's full proportional variance stops looking like a corgi.
    public enum CorgiRange {
        public static let earFlop: ClosedRange<Double> = 0.05...0.65
        public static let earSize: ClosedRange<Double> = 0.40...0.70
        public static let eyeSpacing: ClosedRange<Double> = 0.35...0.60
        public static let eyeOpenness: ClosedRange<Double> = 0.15...0.95
        public static let snoutLength: ClosedRange<Double> = 0.30...0.75
        public static let snoutWidth: ClosedRange<Double> = 0.35...0.65
        public static let cheekFluff: ClosedRange<Double> = 0.30...0.85
    }

    /// Smile strength at or above which the corgi's tongue appears.
    public static let tongueThreshold: Double = 0.35

    /// Converts human facial geometry into corgi facial geometry.
    ///
    /// The result is deterministic: the same input always produces the same
    /// output, which is what makes the pipeline testable.
    public static func map(_ face: FaceFeatures) -> CorgiFeatures {
        // Thicker, heavier brows -> floppier ears.
        let browT = normalize(face.browThickness, from: HumanRange.browThickness)
        let earFlop = denormalize(browT, to: CorgiRange.earFlop)

        // Rounder faces (higher aspect ratio) carry slightly larger ears.
        let aspectT = normalize(face.aspectRatio, from: HumanRange.aspectRatio)
        let earSize = denormalize(aspectT, to: CorgiRange.earSize)

        // A longer face (low aspect ratio) becomes a longer snout, so invert.
        let snoutLength = denormalize(1.0 - aspectT, to: CorgiRange.snoutLength)

        let spacingT = normalize(face.eyeSpacing, from: HumanRange.eyeSpacing)
        let eyeSpacing = denormalize(spacingT, to: CorgiRange.eyeSpacing)

        let opennessT = normalize(face.eyeOpenness, from: HumanRange.eyeOpenness)
        let eyeOpenness = denormalize(opennessT, to: CorgiRange.eyeOpenness)

        let noseT = normalize(face.noseWidth, from: HumanRange.noseWidth)
        let snoutWidth = denormalize(noseT, to: CorgiRange.snoutWidth)

        // Wider faces get a fuller ruff.
        let cheekFluff = denormalize(aspectT, to: CorgiRange.cheekFluff)

        // Smile drives mouth openness; a broad smile also shows the tongue.
        let smileT = normalize(face.smileCurve, from: HumanRange.smileCurve)
        let mouthWidthT = normalize(face.mouthWidth, from: HumanRange.mouthWidth)
        let mouthOpenness = clamp01(0.7 * smileT + 0.3 * mouthWidthT)

        return CorgiFeatures(
            earFlop: earFlop,
            earSize: earSize,
            eyeSpacing: eyeSpacing,
            eyeOpenness: eyeOpenness,
            snoutLength: snoutLength,
            snoutWidth: snoutWidth,
            mouthOpenness: mouthOpenness,
            tongueOut: smileT >= tongueThreshold,
            cheekFluff: cheekFluff,
            headRoll: face.rollDegrees,
            headYaw: face.yawDegrees
        )
    }

    // MARK: - Math helpers

    /// Maps a value from `range` onto 0...1, clamping outside values.
    ///
    /// A zero-width range would divide by zero, so it returns the midpoint.
    public static func normalize(_ value: Double, from range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0.5 }
        return clamp01((value - range.lowerBound) / span)
    }

    /// Maps a 0...1 value onto `range`.
    public static func denormalize(_ t: Double, to range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        return range.lowerBound + clamp01(t) * span
    }

    /// Clamps to 0...1, treating NaN as 0 so bad landmark data cannot poison
    /// the rest of the pipeline.
    public static func clamp01(_ value: Double) -> Double {
        guard !value.isNaN else { return 0 }
        return min(max(value, 0), 1)
    }
}
