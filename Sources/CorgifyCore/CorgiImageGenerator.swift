#if canImport(ImagePlayground)
import CoreGraphics
import Foundation
import ImagePlayground

/// Generates the corgi portrait with Apple's on-device image model.
///
/// `ImageCreator` is the programmatic entry point to Image Playground. It runs
/// against the same on-device generative model that powers the system UI, so
/// the photo never leaves the device.
@available(iOS 18.4, macOS 15.4, *)
public struct CorgiImageGenerator: Sendable {

    public enum GeneratorError: Error, LocalizedError {
        case unsupportedDevice
        case noImageProduced

        public var errorDescription: String? {
            switch self {
            case .unsupportedDevice:
                return "This device cannot generate images. Apple Intelligence is required."
            case .noImageProduced:
                return "The model did not return an image. Try another photo."
            }
        }
    }

    public init() {}

    /// Generates a corgi portrait from the mapped features and the source photo.
    ///
    /// - Parameters:
    ///   - corgi: Features produced by `CorgiFaceMapper`.
    ///   - sourceImage: The original photo, passed so the model can carry over
    ///     pose and lighting. Omit it to generate from the text prompt alone.
    /// - Returns: The generated image.
    public func generate(
        corgi: CorgiFeatures,
        sourceImage: CGImage? = nil
    ) async throws -> CGImage {
        let creator: ImageCreator
        do {
            creator = try await ImageCreator()
        } catch {
            throw GeneratorError.unsupportedDevice
        }

        guard let style = creator.availableStyles.first else {
            throw GeneratorError.unsupportedDevice
        }

        var concepts: [ImagePlaygroundConcept] = [
            .text(CorgiPromptBuilder.prompt(for: corgi))
        ]
        if let sourceImage {
            concepts.append(.image(sourceImage))
        }

        let images = creator.images(for: concepts, style: style, limit: 1)
        for try await created in images {
            return created.cgImage
        }
        throw GeneratorError.noImageProduced
    }
}
#endif
