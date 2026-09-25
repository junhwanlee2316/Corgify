#if canImport(SwiftUI) && canImport(ImagePlayground)
import CoreGraphics
import Foundation
import SwiftUI

/// Drives the capture-to-corgi pipeline and exposes it to the UI.
///
/// The pipeline is: photo -> `FaceAnalyzer` (Vision landmarks) ->
/// `CorgiFaceMapper` (pure geometry) -> `CorgiPromptBuilder` (text) ->
/// `CorgiImageGenerator` (Image Playground). Every step runs on device.
@available(iOS 18.4, macOS 15.4, *)
@MainActor
@Observable
public final class CorgifyViewModel {

    public enum State: Equatable {
        case idle
        case analyzing
        case generating
        case finished
        case failed(String)
    }

    public private(set) var state: State = .idle
    public private(set) var humanFeatures: FaceFeatures?
    public private(set) var corgiFeatures: CorgiFeatures?
    public private(set) var generatedImage: CGImage?

    /// The prompt sent to the image model. Surfaced so the UI can show the
    /// user exactly what was generated from their photo.
    public var prompt: String? {
        corgiFeatures.map(CorgiPromptBuilder.prompt(for:))
    }

    private let analyzer = FaceAnalyzer()
    private let generator = CorgiImageGenerator()

    public init() {}

    /// Runs the full pipeline on a captured photo.
    public func corgify(_ photo: CGImage) async {
        state = .analyzing
        generatedImage = nil

        let features: FaceFeatures
        do {
            features = try analyzer.analyze(photo)
        } catch {
            state = .failed(error.localizedDescription)
            return
        }

        humanFeatures = features
        let corgi = CorgiFaceMapper.map(features)
        corgiFeatures = corgi

        state = .generating
        do {
            generatedImage = try await generator.generate(corgi: corgi, sourceImage: photo)
            state = .finished
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    public func reset() {
        state = .idle
        humanFeatures = nil
        corgiFeatures = nil
        generatedImage = nil
    }
}
#endif
