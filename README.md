# Corgify

Point your camera at a person, get back a corgi with their face.

Corgify maps human facial geometry onto corgi facial geometry, then generates
the portrait with Apple Intelligence. Every step runs on device: the photo is
never uploaded, and the app works in airplane mode.

## How it works

```
photo
  ↓  FaceAnalyzer        Vision face landmarks (Neural Engine, on device)
FaceFeatures             11 normalized measurements
  ↓  CorgiFaceMapper     pure geometry, no ML, fully deterministic
CorgiFeatures            11 corgi traits
  ↓  CorgiPromptBuilder  numbers → English
prompt
  ↓  CorgiImageGenerator Image Playground `ImageCreator` (on device)
corgi portrait
```

### The mapping

The interesting part is `CorgiFaceMapper`, which is an explicit, documented
correspondence rather than a learned black box:

| Human feature      | Corgi feature   | Why |
|--------------------|-----------------|-----|
| eyebrow thickness  | ear flop        | Brows frame human expression the way ears frame a dog's |
| face aspect ratio  | snout length    | A long face reads as a long snout (inverted) |
| face aspect ratio  | cheek fluff     | Wider faces get a fuller ruff |
| eye spacing        | eye spacing     | Direct |
| eye openness       | eye openness    | Direct — squinting carries through |
| nose width         | snout width     | Direct |
| smile curve        | mouth + tongue  | Corgi smiles are open-mouthed; a broad smile shows tongue |
| head roll / yaw    | head pose       | The corgi faces the way the person did |

Human measurements are normalized against observed ranges, then projected into
*narrower* corgi ranges. That clamping is deliberate: a corgi with a human's
full proportional variance stops looking like a corgi.

## Requirements

- iOS 18.4+ (`ImageCreator` was introduced in 18.4)
- A device that supports Apple Intelligence — iPhone 16 or later, or an
  M-series iPad
- Xcode 16+ to build the app target

The `CorgifyCore` mapping logic itself has no platform dependencies and builds
anywhere Swift 6 runs.

## Building

```bash
# Core logic + verification runner (works with just Command Line Tools)
swift build
swift run corgify-verify

# Full app: open Package.swift in Xcode, or create an app target that
# links CorgifyCore and includes App/Corgify/
```

### Why there are two test suites

`Tests/CorgifyCoreTests` uses XCTest and needs a full Xcode install.
`Sources/corgify-verify` is a dependency-free runner covering the same ground,
so the core mapping can be verified in a clean CI container or on a machine
that only has Command Line Tools. CI runs the latter.

## Project layout

```
Sources/CorgifyCore/
  FaceFeatures.swift          normalized human measurements
  CorgiFeatures.swift         corgi traits
  CorgiFaceMapper.swift       the mapping (pure, testable, no dependencies)
  CorgiPromptBuilder.swift    features → prompt text
  FaceAnalyzer.swift          Vision landmark extraction
  CorgiImageGenerator.swift   Image Playground generation
  CorgifyViewModel.swift      pipeline orchestration
App/Corgify/
  CorgifyApp.swift            SwiftUI entry point
  CameraView.swift            AVFoundation capture
Sources/corgify-verify/       dependency-free verification runner (28 checks)
Sources/corgify-analyze/      runs Vision over real photos, reports ranges
scripts/                      fetch validation photos
```

## Validating against real faces

`FaceAnalyzer` has been run against real portraits, and doing so caught two
bugs that unit tests could not:

```bash
./scripts/fetch-validation-photos.sh
swift run corgify-analyze .validation/*.jpg
```

The tool prints every measurement, the resulting prompt, and an observed-vs-
configured range table that flags any feature whose real spread falls outside
`CorgiFaceMapper.HumanRange`:

```
feature          observed          configured        status
aspectRatio       1.133..1.339     1.000..1.450    ok
browThickness     0.465..0.563     0.400..0.620    ok
eyeOpenness       0.288..0.366     0.220..0.420    ok
```

### What real photos revealed

**Vision's `boundingBox` says nothing about face shape.** It is normalized to
image dimensions, so `box.width / box.height` just re-encodes the photo's
aspect ratio. On four test portraits it corrected to exactly 1.000 every time.
Face proportion now comes from the jaw contour instead. Before this fix every
face produced an identical corgi.

**A neutral expression was showing its tongue.** Once `smileCurve` was
calibrated to real data, a deadpan 0.0 normalized to 0.36 — just past the old
0.35 tongue threshold. Raised to 0.60, with a regression check.

The ranges come from a small sample. Re-run the tool on a larger, more varied
set to tighten them; anything that clips is reported.

## Status

The mapping, prompt building, Vision extraction, and pipeline structure are
implemented and verified — 28 automated checks plus real-photo validation.

### Known gaps

- `ImageCreator` has never been executed. It cannot run in CI or the
  Simulator, so generation needs Apple Intelligence hardware (iPhone 16+) to
  validate. Everything upstream of it is tested.
- No Xcode project file is checked in. The app sources are present; the target
  needs creating to deploy to a device.
- `ImagePlaygroundConcept.image(_:)` is used to pass the source photo; confirm
  the exact concept API on your SDK version.
- Validation used four portraits. The normalization ranges will want widening
  as more faces are measured.

## Contributing

Issues and pull requests welcome. The mapping constants in particular are
opinionated guesses — if you have a corgi and a camera, empirical corrections
are the most useful contribution.

## License

MIT — see [LICENSE](LICENSE).
