import CorgifyCore
import Foundation

/// A dependency-free verification runner for the pure mapping logic.
///
/// Why this exists: XCTest and Swift Testing both require a full Xcode
/// install. This executable needs only the Swift toolchain, so the core
/// mapping can be verified anywhere, including a clean CI container or a
/// machine that only has Command Line Tools.
///
/// The XCTest suite in `Tests/` covers the same ground for Xcode users.
///
/// Run with: `swift run corgify-verify`
///
/// Note: everything lives inside the type rather than at top level because
/// Swift 6 isolates top-level `var`s to the main actor, which stops plain
/// functions from mutating them.
@main
struct Verifier {

    var checks = 0
    var failures = 0

    static func main() {
        var verifier = Verifier()
        verifier.run()
        print("\n\(verifier.checks - verifier.failures)/\(verifier.checks) checks passed")
        if verifier.failures > 0 {
            print("FAILED")
            exit(1)
        }
        print("OK")
    }

    mutating func check(_ condition: Bool, _ label: String) {
        checks += 1
        if condition {
            print("  pass  \(label)")
        } else {
            failures += 1
            print("  FAIL  \(label)")
        }
    }

    func section(_ name: String) {
        print("\n\(name)")
    }

    mutating func run() {
        checkRanges()
        checkDeterminism()
        checkFeatureCorrespondence()
        checkBadInput()
        checkPrompts()
    }

    mutating func checkRanges() {
        section("Mapping stays within corgi ranges")
        let corgi = CorgiFaceMapper.map(.neutral)
        check(CorgiFaceMapper.CorgiRange.earFlop.contains(corgi.earFlop), "ear flop in range")
        check(CorgiFaceMapper.CorgiRange.earSize.contains(corgi.earSize), "ear size in range")
        check(CorgiFaceMapper.CorgiRange.eyeSpacing.contains(corgi.eyeSpacing), "eye spacing in range")
        check(CorgiFaceMapper.CorgiRange.eyeOpenness.contains(corgi.eyeOpenness), "eye openness in range")
        check(CorgiFaceMapper.CorgiRange.snoutLength.contains(corgi.snoutLength), "snout length in range")
        check(CorgiFaceMapper.CorgiRange.snoutWidth.contains(corgi.snoutWidth), "snout width in range")
        check(CorgiFaceMapper.CorgiRange.cheekFluff.contains(corgi.cheekFluff), "cheek fluff in range")
        check(corgi.mouthOpenness >= 0 && corgi.mouthOpenness <= 1, "mouth openness in 0...1")
    }

    mutating func checkDeterminism() {
        section("Mapping is deterministic")
        check(CorgiFaceMapper.map(.neutral) == CorgiFaceMapper.map(.neutral), "same input, same output")
    }

    mutating func checkFeatureCorrespondence() {
        section("Human features drive the right corgi features")

        var thinBrows = FaceFeatures.neutral
        thinBrows.browThickness = 0.35
        var thickBrows = FaceFeatures.neutral
        thickBrows.browThickness = 0.75
        check(
            CorgiFaceMapper.map(thickBrows).earFlop > CorgiFaceMapper.map(thinBrows).earFlop,
            "thicker brows produce floppier ears"
        )

        var longFace = FaceFeatures.neutral
        longFace.aspectRatio = 0.60
        var roundFace = FaceFeatures.neutral
        roundFace.aspectRatio = 0.95
        check(
            CorgiFaceMapper.map(longFace).snoutLength > CorgiFaceMapper.map(roundFace).snoutLength,
            "longer face produces a longer snout"
        )
        check(
            CorgiFaceMapper.map(roundFace).cheekFluff > CorgiFaceMapper.map(longFace).cheekFluff,
            "wider face produces more cheek fluff"
        )

        var squinting = FaceFeatures.neutral
        squinting.eyeOpenness = 0.10
        var wideEyed = FaceFeatures.neutral
        wideEyed.eyeOpenness = 0.45
        check(
            CorgiFaceMapper.map(wideEyed).eyeOpenness > CorgiFaceMapper.map(squinting).eyeOpenness,
            "squinting carries through"
        )

        var smiling = FaceFeatures.neutral
        smiling.smileCurve = 0.9
        var frowning = FaceFeatures.neutral
        frowning.smileCurve = -0.4
        check(CorgiFaceMapper.map(smiling).tongueOut, "a broad smile shows the tongue")
        check(!CorgiFaceMapper.map(frowning).tongueOut, "a frown does not show the tongue")

        var tilted = FaceFeatures.neutral
        tilted.rollDegrees = 12.5
        tilted.yawDegrees = -8.0
        let tiltedCorgi = CorgiFaceMapper.map(tilted)
        check(tiltedCorgi.headRoll == 12.5, "head roll carries through unchanged")
        check(tiltedCorgi.headYaw == -8.0, "head yaw carries through unchanged")
    }

    mutating func checkBadInput() {
        section("Bad input degrades safely")

        var absurd = FaceFeatures.neutral
        absurd.browThickness = 99.0
        absurd.aspectRatio = -5.0
        absurd.eyeOpenness = 1000.0
        let absurdCorgi = CorgiFaceMapper.map(absurd)
        check(
            CorgiFaceMapper.CorgiRange.earFlop.contains(absurdCorgi.earFlop),
            "extreme input is clamped"
        )
        check(
            CorgiFaceMapper.CorgiRange.snoutLength.contains(absurdCorgi.snoutLength),
            "negative input is clamped"
        )

        var broken = FaceFeatures.neutral
        broken.browThickness = Double.nan
        check(!CorgiFaceMapper.map(broken).earFlop.isNaN, "NaN does not propagate")

        check(
            CorgiFaceMapper.normalize(5.0, from: 3.0...3.0) == 0.5,
            "zero-width range returns midpoint instead of dividing by zero"
        )
    }

    mutating func checkPrompts() {
        section("Prompt building")

        let neutralPrompt = CorgiPromptBuilder.prompt(for: CorgiFaceMapper.map(.neutral))
        check(neutralPrompt.contains("Pembroke Welsh Corgi"), "prompt names the breed")

        var smiling = FaceFeatures.neutral
        smiling.smileCurve = 0.95
        check(
            CorgiPromptBuilder.prompt(for: CorgiFaceMapper.map(smiling)).contains("tongue out"),
            "smiling prompt mentions the tongue"
        )

        var flat = FaceFeatures.neutral
        flat.smileCurve = -0.5
        flat.mouthWidth = 0.25
        check(
            !CorgiPromptBuilder.prompt(for: CorgiFaceMapper.map(flat)).contains("tongue out"),
            "neutral prompt does not claim the tongue is out"
        )
        check(
            CorgiPromptBuilder.earPhrase(flop: 0.1, size: 0.5).contains("upright"),
            "low flop reads as upright ears"
        )
        check(
            CorgiPromptBuilder.earPhrase(flop: 0.6, size: 0.5).contains("folded"),
            "high flop reads as folded ears"
        )
        check(
            CorgiPromptBuilder.earPhrase(flop: 0.1, size: 0.7).contains("large"),
            "large ears are called out"
        )

        print("\nExample prompt for a neutral face:")
        print("  \(neutralPrompt)")
    }
}
