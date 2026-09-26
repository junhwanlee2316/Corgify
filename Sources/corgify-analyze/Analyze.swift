#if canImport(Vision)
import CorgifyCore
import Foundation
import ImageIO
import Vision

/// Runs the real Vision pipeline over photo files and prints the measurements.
///
/// This exists to validate `FaceAnalyzer` against actual faces. The landmark
/// math was originally written against Vision's documented conventions without
/// ever being checked on a real image; this tool is how those assumptions get
/// tested, and how the normalization ranges in `CorgiFaceMapper.HumanRange`
/// get calibrated instead of guessed.
///
/// Usage: swift run corgify-analyze path/to/photo.jpg [more.jpg ...]
@main
struct Analyze {

    static func main() {
        let paths = Array(CommandLine.arguments.dropFirst())
        guard !paths.isEmpty else {
            print("usage: corgify-analyze <image> [image ...]")
            exit(2)
        }

        let analyzer = FaceAnalyzer()
        var measured: [String: [Double]] = [:]
        var failures = 0

        for path in paths {
            let name = (path as NSString).lastPathComponent
            guard let image = loadImage(path) else {
                print("\(name): could not decode")
                failures += 1
                continue
            }

            do {
                let f = try analyzer.analyze(image)
                let corgi = CorgiFaceMapper.map(f)

                print("\n\(name)")
                print(String(format: "  aspectRatio   %.3f", f.aspectRatio))
                print(String(format: "  eyeSpacing    %.3f", f.eyeSpacing))
                print(String(format: "  eyeOpenness   %.3f", f.eyeOpenness))
                print(String(format: "  noseWidth     %.3f", f.noseWidth))
                print(String(format: "  mouthWidth    %.3f", f.mouthWidth))
                print(String(format: "  smileCurve    %.3f", f.smileCurve))
                print(String(format: "  browThickness %.3f", f.browThickness))
                print(String(format: "  roll/yaw      %.1f / %.1f", f.rollDegrees, f.yawDegrees))
                print("  -> \(CorgiPromptBuilder.prompt(for: corgi))")

                record(&measured, "aspectRatio", f.aspectRatio)
                record(&measured, "eyeSpacing", f.eyeSpacing)
                record(&measured, "eyeOpenness", f.eyeOpenness)
                record(&measured, "noseWidth", f.noseWidth)
                record(&measured, "mouthWidth", f.mouthWidth)
                record(&measured, "smileCurve", f.smileCurve)
                record(&measured, "browThickness", f.browThickness)
            } catch {
                print("\(name): \(error.localizedDescription)")
                failures += 1
            }
        }

        printRanges(measured)

        if measured.isEmpty {
            print("\nNo faces measured.")
            exit(1)
        }
        print("\nAnalyzed \(paths.count - failures)/\(paths.count) images.")
    }

    static func record(_ store: inout [String: [Double]], _ key: String, _ value: Double) {
        store[key, default: []].append(value)
    }

    /// Prints observed min/max per feature next to the ranges currently
    /// hardcoded in `CorgiFaceMapper.HumanRange`, flagging any that clip.
    static func printRanges(_ measured: [String: [Double]]) {
        guard !measured.isEmpty else { return }

        let configured: [String: ClosedRange<Double>] = [
            "aspectRatio": CorgiFaceMapper.HumanRange.aspectRatio,
            "eyeSpacing": CorgiFaceMapper.HumanRange.eyeSpacing,
            "eyeOpenness": CorgiFaceMapper.HumanRange.eyeOpenness,
            "noseWidth": CorgiFaceMapper.HumanRange.noseWidth,
            "mouthWidth": CorgiFaceMapper.HumanRange.mouthWidth,
            "smileCurve": CorgiFaceMapper.HumanRange.smileCurve,
            "browThickness": CorgiFaceMapper.HumanRange.browThickness
        ]

        print("\n\nObserved vs configured ranges")
        print("feature          observed          configured        status")
        for key in configured.keys.sorted() {
            guard let values = measured[key], let lo = values.min(), let hi = values.max() else {
                continue
            }
            let range = configured[key]!
            let clipsLow = lo < range.lowerBound
            let clipsHigh = hi > range.upperBound
            let status = clipsLow || clipsHigh ? "CLIPS" : "ok"
            print(String(
                format: "%-16s %6.3f..%-6.3f   %6.3f..%-6.3f   %@",
                (key as NSString).utf8String!,
                lo, hi,
                range.lowerBound, range.upperBound,
                status
            ))
        }
    }

    static func loadImage(_ path: String) -> CGImage? {
        let url = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
#endif
