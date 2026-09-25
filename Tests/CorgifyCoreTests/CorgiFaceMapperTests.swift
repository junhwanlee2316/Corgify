import XCTest
@testable import CorgifyCore

final class CorgiFaceMapperTests: XCTestCase {

    func testNeutralFaceIsInRange() {
        let corgi = CorgiFaceMapper.map(.neutral)

        XCTAssertTrue(CorgiFaceMapper.CorgiRange.earFlop.contains(corgi.earFlop))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.earSize.contains(corgi.earSize))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.eyeSpacing.contains(corgi.eyeSpacing))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.eyeOpenness.contains(corgi.eyeOpenness))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.snoutLength.contains(corgi.snoutLength))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.snoutWidth.contains(corgi.snoutWidth))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.cheekFluff.contains(corgi.cheekFluff))
        XCTAssertGreaterThanOrEqual(corgi.mouthOpenness, 0)
        XCTAssertLessThanOrEqual(corgi.mouthOpenness, 1)
    }

    func testMappingIsDeterministic() {
        XCTAssertEqual(CorgiFaceMapper.map(.neutral), CorgiFaceMapper.map(.neutral))
    }

    func testThickerBrowsProduceFloppierEars() {
        var thin = FaceFeatures.neutral
        thin.browThickness = 0.35
        var thick = FaceFeatures.neutral
        thick.browThickness = 0.75

        XCTAssertGreaterThan(
            CorgiFaceMapper.map(thick).earFlop,
            CorgiFaceMapper.map(thin).earFlop
        )
    }

    func testLongerFaceProducesLongerSnout() {
        // A lower aspect ratio means a taller, narrower face.
        var longFace = FaceFeatures.neutral
        longFace.aspectRatio = 0.60
        var roundFace = FaceFeatures.neutral
        roundFace.aspectRatio = 0.95

        XCTAssertGreaterThan(
            CorgiFaceMapper.map(longFace).snoutLength,
            CorgiFaceMapper.map(roundFace).snoutLength
        )
    }

    func testWiderFaceProducesMoreCheekFluff() {
        var narrow = FaceFeatures.neutral
        narrow.aspectRatio = 0.60
        var wide = FaceFeatures.neutral
        wide.aspectRatio = 0.95

        XCTAssertGreaterThan(
            CorgiFaceMapper.map(wide).cheekFluff,
            CorgiFaceMapper.map(narrow).cheekFluff
        )
    }

    func testBroadSmileShowsTongueAndFrownDoesNot() {
        var smiling = FaceFeatures.neutral
        smiling.smileCurve = 0.9
        var frowning = FaceFeatures.neutral
        frowning.smileCurve = -0.4

        XCTAssertTrue(CorgiFaceMapper.map(smiling).tongueOut)
        XCTAssertFalse(CorgiFaceMapper.map(frowning).tongueOut)
    }

    func testSquintCarriesThrough() {
        var squint = FaceFeatures.neutral
        squint.eyeOpenness = 0.10
        var wide = FaceFeatures.neutral
        wide.eyeOpenness = 0.45

        XCTAssertGreaterThan(
            CorgiFaceMapper.map(wide).eyeOpenness,
            CorgiFaceMapper.map(squint).eyeOpenness
        )
    }

    func testHeadPoseCarriesThroughUnchanged() {
        var tilted = FaceFeatures.neutral
        tilted.rollDegrees = 12.5
        tilted.yawDegrees = -8.0

        let corgi = CorgiFaceMapper.map(tilted)
        XCTAssertEqual(corgi.headRoll, 12.5, accuracy: 0.0001)
        XCTAssertEqual(corgi.headYaw, -8.0, accuracy: 0.0001)
    }

    func testOutOfRangeInputIsClamped() {
        var absurd = FaceFeatures.neutral
        absurd.browThickness = 99.0
        absurd.aspectRatio = -5.0
        absurd.eyeOpenness = 1000.0

        let corgi = CorgiFaceMapper.map(absurd)
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.earFlop.contains(corgi.earFlop))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.snoutLength.contains(corgi.snoutLength))
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.eyeOpenness.contains(corgi.eyeOpenness))
    }

    func testNaNInputDegradesSafely() {
        var broken = FaceFeatures.neutral
        broken.browThickness = Double.nan

        let corgi = CorgiFaceMapper.map(broken)
        XCTAssertFalse(corgi.earFlop.isNaN)
        XCTAssertTrue(CorgiFaceMapper.CorgiRange.earFlop.contains(corgi.earFlop))
    }

    func testZeroWidthRangeReturnsMidpoint() {
        XCTAssertEqual(CorgiFaceMapper.normalize(5.0, from: 3.0...3.0), 0.5, accuracy: 0.0001)
    }
}

final class CorgiPromptBuilderTests: XCTestCase {

    func testPromptNamesTheBreed() {
        let prompt = CorgiPromptBuilder.prompt(for: CorgiFaceMapper.map(.neutral))
        XCTAssertTrue(prompt.contains("Pembroke Welsh Corgi"))
    }

    func testSmilingPromptMentionsTongue() {
        var smiling = FaceFeatures.neutral
        smiling.smileCurve = 0.95
        let prompt = CorgiPromptBuilder.prompt(for: CorgiFaceMapper.map(smiling))
        XCTAssertTrue(prompt.contains("tongue out"))
    }

    func testNeutralPromptDoesNotClaimTongueIsOut() {
        var flat = FaceFeatures.neutral
        flat.smileCurve = -0.5
        flat.mouthWidth = 0.25
        let prompt = CorgiPromptBuilder.prompt(for: CorgiFaceMapper.map(flat))
        XCTAssertFalse(prompt.contains("tongue out"))
    }

    func testEarPhraseTracksFlopAmount() {
        XCTAssertTrue(CorgiPromptBuilder.earPhrase(flop: 0.1, size: 0.5).contains("upright"))
        XCTAssertTrue(CorgiPromptBuilder.earPhrase(flop: 0.6, size: 0.5).contains("folded"))
    }

    func testLargeEarsAreMentioned() {
        XCTAssertTrue(CorgiPromptBuilder.earPhrase(flop: 0.1, size: 0.7).contains("large"))
        XCTAssertFalse(CorgiPromptBuilder.earPhrase(flop: 0.1, size: 0.4).contains("large"))
    }
}
