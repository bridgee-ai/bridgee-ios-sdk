# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Bridgee iOS SDK — a marketing-attribution SDK distributed as both a Swift Package (product name `BridgeeSDK`) and a CocoaPod (pod name `BridgeeAiSDK`, version in `BridgeeAiSDK.podspec`). It POSTs to `https://api.bridgee.ai/match` to resolve UTM data for a first-open event and forwards events to a host-app analytics implementation.

- iOS 14.0+, Swift 5.5+, no external dependencies.
- Source lives under `Sources/BridgeeSDK/`; tests under `Tests/BridgeeSDKTests/`.
- `Examples/ExampleApp.swift` is reference documentation only — it imports `FirebaseAnalytics`, which the SDK target does **not** depend on, so it will not compile as part of the package.

## Build / Test

Use Swift Package Manager from the repo root:

```bash
swift build                                # build the BridgeeSDK target
swift test                                 # run all tests
swift test --filter BridgeeSDKTests.testMatchBundleCreation   # single test
```

To validate the CocoaPods spec after editing `BridgeeAiSDK.podspec`:

```bash
pod lib lint BridgeeAiSDK.podspec
```

When bumping a release, the version in `BridgeeAiSDK.podspec` (`s.version`) must match the git tag the podspec points at via `s.source[:tag]`.

## Architecture

The SDK is intentionally tiny and centers on three public types plus an internal API layer:

- **`BridgeeSDK`** (`Sources/BridgeeSDK/BridgeeSDK.swift`) — `@objc` singleton (`BridgeeSDK.shared`). `configure(provider:tenantId:tenantKey:dryRun:)` builds the `x-tenant-token` header by base64-encoding `"{tenantId};{tenantKey}"`. `firstOpen(with:completion:)` performs the match request, then on success fires four analytics events (`first_open`, `campaign_details`, and tenant-prefixed variants where `-` in `tenantId` is replaced with `_`) and sets three user properties (`install_source`, `install_medium`, `install_campaign`). On HTTP 404 it deliberately returns an *empty* `UTMData` with no error — callers must not treat 404 as failure.
- **`MatchBundle`** (`MatchBundle.swift`) — opaque key/value container. Convenience setters use fixed keys (`user_name`, `user_email`, `user_phone`, `gclid`); `setCustom(key:value:)` accepts arbitrary keys. `asAPIBody()` serializes to the wire shape `{"metadata": [{"key": "...", "value": "..."}]}` defined by `APIRequest` in `Internal/APIMode.swift`.
- **`AnalyticsProvider`** (`AnalyticsProvider.swift`) — `@objc` protocol the host app implements to bridge to its analytics SDK (Firebase or otherwise). The SDK has no Firebase dependency; that integration is the caller's responsibility.
- **`Internal/APIMode.swift`** — request/response Codables and `APIError` (with user-facing messages). When adding new error cases, update `errorDescription` so the public completion's `String?` argument stays meaningful.

`dryRun: true` still hits the API and still invokes the completion with real `UTMData`, but skips all `provider` calls — preserve this behavior when modifying `firstOpen`.

## Public API surface and Obj-C compatibility

`BridgeeSDK`, `UTMData`, `MatchBundle`, and `AnalyticsProvider` are all `@objc` / `@objcMembers`. Any change to their signatures is a breaking change for both Swift and Obj-C consumers. The completion type is `((UTMData?, String?) -> Void)` — `UTMData` on success (including the empty-on-404 case), error message string on failure, never both.

## Known inconsistency

`Tests/BridgeeSDKTests/BridgeeSDKTests.swift` and `Examples/ExampleApp.swift` call `firstOpen` with signatures that no longer exist (`await sdk.firstOpen(with:)` and a single-arg `(UTMData?) -> Void` completion). The current implementation only exposes `firstOpen(with:completion:)` with a two-arg completion. `swift test` will not compile until the test file is updated; if you touch tests, fix this first.

## Privacy manifest

`Sources/BridgeeSDK/Resources/PrivacyInfo.xcprivacy` is shipped via SPM (`Package.swift` → `.process(...)`) and CocoaPods (`s.resource_bundles`). Keep both in sync if the manifest moves or is renamed.
