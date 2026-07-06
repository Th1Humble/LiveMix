# LiveMix Native iOS

Native SwiftUI implementation of LiveMix.

## Current Scope

- SwiftUI `NavigationStack` app shell
- Native home screen and template picker
- Native image tools:
  - horizontal image join
  - vertical image join
  - one image split into 9 tiles
- Local image rendering through UIKit/CoreGraphics
- Saving generated images to Photos through PhotoKit
- Native Live Photo flow:
  - native video picker
  - template slot state
  - local AVFoundation video composition
  - local still-frame extraction
  - Live Photo metadata pairing
  - saving paired resources to Photos through PhotoKit

The Live engine runs locally through AVFoundation and PhotoKit. The app should not upload user videos or photos to a server.

## Run

Open:

```text
ios/LiveCollageNative/LivePhotoCollage.xcodeproj
```

Select the `LivePhotoCollage` target and run on an iPhone or simulator.

Bundle identifier defaults to:

```text
com.livephotocollage.native
```

Change the Team / Bundle Identifier in Xcode if needed before running on a physical iPhone.
