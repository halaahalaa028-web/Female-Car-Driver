# iOS release checklist — Female Captain (driver app)

| | |
|---|---|
| Bundle ID | `com.femalecarrider.eon` |
| Firebase iOS App ID | `1:993077501425:ios:a0ccaa680ebefc0ca2b850` |
| Firebase project | `female-car-1e241` |

## Before building (on the Mac)
1. Apple Developer → Identifiers: create the App ID `com.femalecarrider.eon` with **Push Notifications** enabled.
2. App Store Connect → New App using the same bundle id.
3. Firebase → Project settings → Cloud Messaging → upload the **APNs Auth Key (.p8)** for this app (add the Team ID).
4. Maps: the app uses OpenStreetMap — no API key is needed.

## Build
```bash
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release
```
Open `ios/Runner.xcworkspace` in Xcode, pick the Team (Automatic signing) and upload with Organizer/Transporter.

## Must stay consistent (otherwise the app shows a black screen at launch)
`ios/Runner/GoogleService-Info.plist` ⇄ `lib/firebase_options.dart` (iOS block) ⇄ `PRODUCT_BUNDLE_IDENTIFIER` in Xcode.
`flutter test test/ios` checks all of this; run it before every iOS build.

## Verify in Xcode
Runner → Build Phases → *Copy Bundle Resources* contains `GoogleService-Info.plist`.
