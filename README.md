# Pet Arena

A card-battle game for your phone. You can play it in a browser (`Pet Arena (1).html`), or install it as an Android app or an iPhone/iPad app.

## Android app

`android/` is an Android Studio project. It runs the game full screen in a `WebView`:

- It plays fully offline. The game HTML and its fonts (Lilita One and Creepster) come bundled inside the APK.
- Your progress (trophies, coins, deck) is kept between launches.
- It uses `IMG_0266.png` as the app icon.
- The build copies `Pet Arena (1).html` from the repo root and the fonts from `ios/PetArena/Web/`. When you change the game, rebuild the app and it picks up the change.

### Install the APK

GitHub Actions (`.github/workflows/android.yml`) builds the APK on every push:

1. Open the repo's **Actions** tab and click the latest **Android build** run.
2. Download **PetArena-apk** from the run's artifacts. It is a zip that contains `PetArena.apk`.
3. Copy `PetArena.apk` to your phone and open it. Android asks you to allow installs from that app (your browser or file manager) the first time.

The APK is signed with a fixed debug key (`android/app/debug.keystore`), so it installs directly and each new build installs over the last one without losing your progress. To publish on Google Play, sign it with your own private release key.

To build it yourself, open `android/` in Android Studio, or run:

```sh
cd android && ./gradlew assembleRelease
```

The APK lands in `android/app/build/outputs/apk/release/`.

## iOS app

`ios/PetArena.xcworkspace` (with the project `ios/PetArena.xcodeproj`) is a SwiftUI app. It runs the game full screen in a `WKWebView`:

- It plays fully offline. The game HTML and its fonts (Lilita One and Creepster) come bundled inside the app.
- Your progress (trophies, coins, deck) is kept between launches.
- It uses `IMG_0266.png` as the app icon.
- The app loads `Pet Arena (1).html` straight from the repo root. When you change the game, rebuild the app and it picks up the change.

### Run it on your iPhone

1. You need a Mac with Xcode 16 or newer. Open `ios/PetArena.xcworkspace`.
2. Select the **PetArena** target, then open **Signing & Capabilities**.
   - Choose your **Team**. A free Apple ID works for testing on your own phone.
   - Change the **Bundle Identifier** (`com.petarena.game`) to one of your own, such as `com.yourname.petarena`.
3. Connect your iPhone, select it as the run destination, and press **Run** (⌘R).
   - The first time, you may need to turn on Developer Mode on the iPhone.
   - You may also need to trust your developer certificate under Settings → General → VPN & Device Management.

### Publish to the App Store / TestFlight

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).
2. In Xcode choose **Product → Archive**, then click **Distribute App → App Store Connect**.
3. Complete the listing in [App Store Connect](https://appstoreconnect.apple.com): screenshots, description, privacy details (the app collects no data) and age rating.

### Build without a Mac

GitHub Actions (`.github/workflows/ios.yml`) builds the app on every push. To get the build:

1. Open the repo's **Actions** tab and click the latest **iOS build** run.
2. Download **PetArena-unsigned-ipa** from the run's artifacts. It is a zip that contains `PetArena-unsigned.ipa`.

The IPA is unsigned, so an iPhone will not install it as-is. A sideloading tool such as [Sideloadly](https://sideloadly.io) or [AltStore](https://altstore.io) can sign it with your Apple ID and install it from Windows or a Mac. With a free Apple ID the app stops working after 7 days, and you have to install it again.

To compile locally from the command line:

```sh
xcodebuild build -workspace ios/PetArena.xcworkspace -scheme PetArena \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```
