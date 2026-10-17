# Pet Arena

A card-battle game for your phone. You can play it in a browser (`Pet Arena (1).html`) or install it as an iPhone/iPad app.

## iOS app

`ios/PetArena.xcodeproj` is a SwiftUI app. It runs the game full screen in a `WKWebView`:

- It plays fully offline. The game HTML and the Lilita One font come bundled inside the app.
- Your progress (trophies, coins, deck) is kept between launches.
- It uses `IMG_0266.png` as the app icon.
- The app loads `Pet Arena (1).html` straight from the repo root. When you change the game, rebuild the app and it picks up the change.

### Run it on your iPhone

1. You need a Mac with Xcode 16 or newer. Open `ios/PetArena.xcodeproj`.
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

Every push builds the app for the iOS Simulator in GitHub Actions (`.github/workflows/ios.yml`).
