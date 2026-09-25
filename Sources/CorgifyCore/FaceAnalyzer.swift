#if canImport(Vision)
import CoreGraphics
import Foundation
import Vision

/// Extracts `FaceFeatures` from a photo using the Vision framework.
///
/// Vision runs on the Neural Engine and never leaves the device, which is why
/// the whole pipeline can stay local.
public struct FaceAnalyzer: Sendable {

    public enum AnalyzerError: Error, LocalizedError {
        case noFaceFound
        case multipleFacesFound(count: Int)
        case landmarksUnavailable

        public var errorDescription: String? {
            switch self {
            case .noFaceFound:
                return "No face was found in the photo."
            case .multipleFacesFound(let count):
                return "Found \(count) faces. Point the camera at one person."
            case .landmarksUnavailable:
                return "The face was detected but its features could not be read clearly."
            }
        }
    }

    public init() {}

    /// Analyzes a single face in the image.
    ///
    /// Throws when there is no face, more than one face, or when landmarks are
    /// too incomplete to measure. Failing loudly here is deliberate: a silent
    /// fallback would produce a corgi unrelated to the person in the photo.
    public func analyze(_ image: CGImage) throws -> FaceFeatures {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            throw AnalyzerError.noFaceFound
        }
        guard observations.count == 1 else {
            throw AnalyzerError.multipleFacesFound(count: observations.count)
        }
        return try features(from: observations[0])
    }

    /// Converts one Vision observation into normalized features.
    func features(from observation: VNFaceObservation) throws -> FaceFeatures {
        guard let landmarks = observation.landmarks else {
            throw AnalyzerError.landmarksUnavailable
        }

        let box = observation.boundingBox
        guard box.width > 0, box.height > 0 else {
            throw AnalyzerError.landmarksUnavailable
        }

        var features = FaceFeatures.neutral
        // Vision reports the box in normalized image coordinates, so the ratio
        // of its own width to height is already resolution-independent.
        features.aspectRatio = Double(box.width / box.height)

        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftCenter = centroid(of: leftEye)
            let rightCenter = centroid(of: rightEye)
            features.eyeSpacing = Double(abs(rightCenter.x - leftCenter.x))
            features.eyeHeight = Double(1.0 - (leftCenter.y + rightCenter.y) / 2.0)
            features.eyeOpenness = (openness(of: leftEye) + openness(of: rightEye)) / 2.0
        }

        if let nose = landmarks.nose {
            let extent = extent(of: nose)
            features.noseWidth = Double(extent.width)
            features.noseHeight = Double(1.0 - centroid(of: nose).y)
        }

        if let mouth = landmarks.outerLips {
            let extent = extent(of: mouth)
            features.mouthWidth = Double(extent.width)
            features.smileCurve = smileCurve(of: mouth)
        }

        let browWidths = [landmarks.leftEyebrow, landmarks.rightEyebrow]
            .compactMap { $0 }
            .map { Double(extent(of: $0).width) }
        if !browWidths.isEmpty {
            features.browThickness = browWidths.reduce(0, +)
        }

        features.rollDegrees = observation.roll.map { Double(truncating: $0) * 180 / .pi } ?? 0
        features.yawDegrees = observation.yaw.map { Double(truncating: $0) * 180 / .pi } ?? 0

        return features
    }

    // MARK: - Landmark geometry

    func centroid(of region: VNFaceLandmarkRegion2D) -> CGPoint {
        let points = region.normalizedPoints
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) {
            CGPoint(x: $0.x + $1.x, y: $0.y + $1.y)
        }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    func extent(of region: VNFaceLandmarkRegion2D) -> CGSize {
        let points = region.normalizedPoints
        guard !points.isEmpty else { return .zero }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let width = (xs.max() ?? 0) - (xs.min() ?? 0)
        let height = (ys.max() ?? 0) - (ys.min() ?? 0)
        return CGSize(width: width, height: height)
    }

    /// Eye height divided by eye width. A closed eye approaches 0.
    func openness(of eye: VNFaceLandmarkRegion2D) -> Double {
        let size = extent(of: eye)
        guard size.width > 0 else { return 0 }
        return Double(size.height / size.width)
    }

    /// Positive when the mouth corners sit above the vertical center of the
    /// lips, which is what a smile looks like in landmark space.
    func smileCurve(of mouth: VNFaceLandmarkRegion2D) -> Double {
        let points = mouth.normalizedPoints
        guard points.count >= 4 else { return 0 }

        let sorted = points.sorted { $0.x < $1.x }
        guard let leftCorner = sorted.first, let rightCorner = sorted.last else { return 0 }

        let cornerY = (leftCorner.y + rightCorner.y) / 2
        let centerY = centroid(of: mouth).y
        let size = extent(of: mouth)
        guard size.height > 0 else { return 0 }

        // Vision's y axis points up, so corners above center means y is larger.
        return Double((cornerY - centerY) / size.height) * 2.0
    }
}
#endif
