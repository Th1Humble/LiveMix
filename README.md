# LiveMix

Native iOS app for making Live Photo and image collages.

## Scope

- **Live 拼接**：多段视频选择模板后在本机合成为一张 Live Photo。
- **图片拼接**：左右拼接、上下拼接，支持图片和 Live Photo 输入。
- **九宫格切图**：一张图片切成 9 张方图，适合朋友圈/社交平台发布。
- **本机保存**：通过 PhotoKit 写入系统相册，不依赖服务端。
- **中英双语**：App 内可切换中文/英文，系统权限文案也支持中英本地化。

## Tech

| Area | Stack |
| --- | --- |
| App | SwiftUI |
| Media | AVFoundation, CoreGraphics, UIKit |
| Photos | PhotoKit, PhotosUI |
| Tests | Swift command-line regression tests + Xcode build |

## Run

Open the native project:

```text
ios/LiveCollageNative/LivePhotoCollage.xcodeproj
```

Then select the `LivePhotoCollage` scheme and run on an iPhone or simulator.

For physical iPhone testing, set your Team and Bundle Identifier in Xcode first.

## Verify

Build the app:

```bash
xcodebuild -project ios/LiveCollageNative/LivePhotoCollage.xcodeproj \
  -scheme LivePhotoCollage \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath /private/tmp/liveCollageNative-derivedData \
  build
```

Run core logic tests:

```bash
env CLANG_MODULE_CACHE_PATH=/private/tmp/livecollage-clang-cache \
  SWIFT_MODULECACHE_PATH=/private/tmp/livecollage-swift-cache \
  xcrun swiftc -parse-as-library \
  ios/LiveCollageNative/LivePhotoCollage/CollageModels.swift \
  ios/LiveCollageNativeTests/CollageCoreTests.swift \
  -o /private/tmp/CollageCoreTests \
  && /private/tmp/CollageCoreTests
```

## Live Photo Notes

Apple Live Photo is saved as paired resources: one still image and one paired MOV with matching metadata. LiveMix handles this inside the iOS app through AVFoundation and PhotoKit, then writes the result directly to Photos.
