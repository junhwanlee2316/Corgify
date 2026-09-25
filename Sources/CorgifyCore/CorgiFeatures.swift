import Foundation

/// A corgi's facial configuration, derived from a human face.
///
/// Values are normalized 0...1 unless noted. The renderer (or the prompt
/// builder) consumes these rather than raw human measurements, which keeps
/// "how a human maps to a corgi" in exactly one place: `CorgiFaceMapper`.
public struct CorgiFeatures: Equatable, Sendable {

    /// How far the ears flop. 0 = fully upright (classic corgi alert),
    /// 1 = fully folded down.
    public var earFlop: Double

    /// Ear size relative to the head. 0.5 is breed-typical.
    public var earSize: Double

    /// How far apart the eyes sit. 0.5 is breed-typical.
    public var eyeSpacing: Double

    /// Eye openness. 0 = closed/squinting, 1 = wide alert.
    public var eyeOpenness: Double

    /// Snout length. 0 = flat/brachycephalic, 1 = long.
    public var snoutLength: Double

    /// Snout width at the bridge.
    public var snoutWidth: Double

    /// Mouth openness — drives the classic corgi "smile" with tongue out.
    public var mouthOpenness: Double

    /// Whether the tongue shows. Derived from smile intensity.
    public var tongueOut: Bool

    /// Fluffiness of the cheek ruff. Maps from human face width.
    public var cheekFluff: Double

    /// Head roll in degrees, carried straight through from the human pose.
    public var headRoll: Double

    /// Head yaw in degrees, carried straight through from the human pose.
    public var headYaw: Double

    public init(
        earFlop: Double,
        earSize: Double,
        eyeSpacing: Double,
        eyeOpenness: Double,
        snoutLength: Double,
        snoutWidth: Double,
        mouthOpenness: Double,
        tongueOut: Bool,
        cheekFluff: Double,
        headRoll: Double,
        headYaw: Double
    ) {
        self.earFlop = earFlop
        self.earSize = earSize
        self.eyeSpacing = eyeSpacing
        self.eyeOpenness = eyeOpenness
        self.snoutLength = snoutLength
        self.snoutWidth = snoutWidth
        self.mouthOpenness = mouthOpenness
        self.tongueOut = tongueOut
        self.cheekFluff = cheekFluff
        self.headRoll = headRoll
        self.headYaw = headYaw
    }
}
