import CoreGraphics
import Foundation

/// A normalized description of a human face, extracted from Vision landmarks.
///
/// All values are normalized so they are resolution-independent: ratios are
/// unitless, angles are in degrees, and positions are fractions of the
/// detected face bounding box. This makes the mapping stable whether the
/// source photo is 12MP or a thumbnail.
public struct FaceFeatures: Equatable, Sendable {

    /// Width of the face divided by its height. Wider faces > 1.0.
    public var aspectRatio: Double

    /// Distance between pupils, as a fraction of face width.
    public var eyeSpacing: Double

    /// Eye opening height divided by eye width. Squinting approaches 0.
    public var eyeOpenness: Double

    /// Vertical position of the eye line, 0 = top of face, 1 = chin.
    public var eyeHeight: Double

    /// Nose bounding width as a fraction of face width.
    public var noseWidth: Double

    /// Nose tip vertical position, 0 = top of face, 1 = chin.
    public var noseHeight: Double

    /// Mouth corner-to-corner width as a fraction of face width.
    public var mouthWidth: Double

    /// Positive when the mouth corners sit above the mouth center (a smile).
    /// Roughly -1 (frown) to 1 (broad smile).
    public var smileCurve: Double

    /// Combined width of both eyebrows as a fraction of face width.
    public var browThickness: Double

    /// Head roll in degrees. 0 is level, positive tilts to the subject's right.
    public var rollDegrees: Double

    /// Head yaw in degrees. 0 faces the camera, positive turns right.
    public var yawDegrees: Double

    public init(
        aspectRatio: Double,
        eyeSpacing: Double,
        eyeOpenness: Double,
        eyeHeight: Double,
        noseWidth: Double,
        noseHeight: Double,
        mouthWidth: Double,
        smileCurve: Double,
        browThickness: Double,
        rollDegrees: Double,
        yawDegrees: Double
    ) {
        self.aspectRatio = aspectRatio
        self.eyeSpacing = eyeSpacing
        self.eyeOpenness = eyeOpenness
        self.eyeHeight = eyeHeight
        self.noseWidth = noseWidth
        self.noseHeight = noseHeight
        self.mouthWidth = mouthWidth
        self.smileCurve = smileCurve
        self.browThickness = browThickness
        self.rollDegrees = rollDegrees
        self.yawDegrees = yawDegrees
    }

    /// A neutral, front-facing reference face. Useful as a test baseline and
    /// as a fallback when landmark detection returns partial data.
    public static let neutral = FaceFeatures(
        aspectRatio: 0.75,
        eyeSpacing: 0.42,
        eyeOpenness: 0.30,
        eyeHeight: 0.42,
        noseWidth: 0.24,
        noseHeight: 0.60,
        mouthWidth: 0.38,
        smileCurve: 0.0,
        browThickness: 0.55,
        rollDegrees: 0.0,
        yawDegrees: 0.0
    )
}
