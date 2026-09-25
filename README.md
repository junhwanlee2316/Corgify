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
Sources/corgify-verify/       dependency-free verification runner
```

## Status

Skeleton. The mapping, prompt building, and pipeline structure are implemented
and verified (27 checks). The camera capture path and the Xcode app target are
scaffolded but have not been run on a physical device — `ImageCreator` cannot
be exercised in CI or the Simulator, so that step needs Apple Intelligence
hardware to validate.

### Known gaps

- The `FaceAnalyzer` landmark math is written against Vision's documented
  coordinate conventions but has not been checked against real photos; the
  normalization ranges in `CorgiFaceMapper.HumanRange` are reasoned estimates
  and will want tuning once real landmark data is available.
- No Xcode project file is checked in. The app sources are present; the target
  needs to be created (or an `.xcodeproj` generated) to ship to a device.
- `ImagePlaygroundConcept.image(_:)` is used to pass the source photo; confirm
  the exact concept API on your SDK version.

## Contributing

Issues and pull requests welcome. The mapping constants in particular are
opinionated guesses — if you have a corgi and a camera, empirical corrections
are the most useful contribution.

## License

MIT — see [LICENSE](LICENSE).
