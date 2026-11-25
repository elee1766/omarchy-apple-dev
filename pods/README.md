# CocoaPods apps (Expo / React Native) on Linux

Builds an iOS app whose native side comes from CocoaPods, for example an Expo app after `expo prebuild`,
on Linux. The build engine is Apple's open-source Swift Build, driven by
[sweetpad](https://github.com/sweetpad-dev/sweetpad), against the Darwin SDK imported from an Xcode `.xip`.
This directory holds what CocoaPods, Expo and React Native expect from a Mac and do not find on Linux.

Verified 2026-11-25: an Expo 58 / React Native 0.88.1 app with 176 pods (Stripe through SwiftPM, Skia,
Reanimated, MMKV/Nitro, Expo modules) built in Release for arm64 iPhone, unsigned, in the Arch container
below. The result: `Oku.app` with an arm64 executable, 24 embedded frameworks and a Hermes bytecode
bundle. Not yet done: signing, install on a phone, launch.

## Use

```
docker build -t rn-ios-linux -f pods/Dockerfile .
# once: Swift and the Darwin SDK, into a volume
docker run --rm -v rn-ios-home:/home/b -v ~/Downloads/Xcode_27.2.xip:/xcode.xip:ro rn-ios-linux \
  sweetpad setup --sdk /xcode.xip --non-interactive
# per build: JS dependencies installed in the app repo first
docker run --rm -v rn-ios-home:/home/b -v $PWD:/oad -v /path/to/repo:/work rn-ios-linux sh -c \
  '. ~/.config/sweetpad/linux-env.sh && /oad/pods/prepare.sh /work/apps/mobile && /oad/pods/build.sh /work/apps/mobile'
```

The app lands in `<app>/ios/build/dd/Build/Products/Release-iphoneos/` (set `DERIVED_DATA` to move it).

## What each piece covers

| Piece | Mac behavior it stands in for |
|---|---|
| `bin/xcodebuild` | `-version` for React Native's Podfile check. `build -scheme` of a Swift package, for Expo's `build-xcframework.sh` (ExpoModulesJSI): builds the dynamic library with SwiftPM and lays it out as Xcode's package build does. |
| `bin/xcrun` | `--show-sdk-path/-version`, and `clang`/`swiftc` with the SDK, for pod prepare scripts. |
| `bin/command` | `/usr/bin/command`, which macOS has and Ruby backticks in React Native's helpers exec directly. |
| `bin/shasum` | macOS `shasum -a N`, used by Expo build scripts. |
| bsdtar as `/usr/bin/tar` | Expo's precompiled-module check reads tarball members by glob, which GNU tar does not do. Without it every Expo module builds from source. |
| `prepare.sh` | Puts expo-modules-macros' Linux binary where swiftc loads the macro plugin, and enables Expo's `@ExpoModule` scan, which autolinking skips off macOS. |
| `fix-pods-project.rb` | Links Swift package products listed in `packageProductDependencies` (Xcode does; Swift Build needs a Frameworks build file), adds Stripe3DS2's module map to its importers, and types `.icon` files so actool gets them. |

ExpoModulesJSI also needs two compiler differences handled, both in `bin/xcodebuild`: `<swift/bridging>`
comes from the Swift toolchain's `include/`, and the open-source Swift needs the
`AssumeResilientCxxTypes` feature for C++ types in a library-evolution module, which Xcode's Swift accepts.
It links with sweetpad's bundled lld, since the Swift toolchain's `ld64.lld` refuses iOS.
