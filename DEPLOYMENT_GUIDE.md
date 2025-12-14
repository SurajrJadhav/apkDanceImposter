# App Store Deployment Guide

This guide will help you prepare and deploy your Group Manager app to both Google Play Store and Apple App Store.

## Prerequisites

### Google Play Store
- **Google Play Developer Account**: $25 one-time registration fee
- **Developer Console Access**: https://play.google.com/console

### Apple App Store
- **Apple Developer Account**: $99/year subscription
- **Mac Computer**: Required for iOS builds and submission
- **Xcode**: Latest version installed

---

## Part 1: Firebase Setup

Before building for production, you must configure Firebase:

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Install FlutterFire CLI**:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. **Configure Firebase**:
   ```bash
   cd g:\apk_dance-imposter
   flutterfire configure
   ```
   
   This will:
   - Create/select a Firebase project
   - Register Android and iOS apps
   - Generate `firebase_options.dart`
   - Download configuration files

4. **Enable Firebase Services**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Enable **Authentication** → Email/Password
   - Enable **Firestore Database** → Start in production mode
   - Set up Firestore Security Rules (see FIREBASE_SETUP.md)

---

## Part 2: Android Build & Deployment

### Step 1: Generate Signing Key

```bash
keytool -genkey -v -keystore g:\apk_dance-imposter\android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important**: Save the password and alias information securely!

### Step 2: Configure Signing

Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=upload-keystore.jks
```

Update `android/app/build.gradle.kts` to add signing configuration (see implementation plan for details).

### Step 3: Build Release APK/AAB

```bash
# Build APK (for testing)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Step 4: Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app
3. Fill in app details:
   - App name: "Group Manager"
   - Category: Social
   - Add screenshots (minimum 2)
   - Add app icon (512x512 PNG)
   - Write description
4. Go to "Production" → "Create new release"
5. Upload `app-release.aab`
6. Submit for review

**Review time**: Usually 1-3 days

---

## Part 3: iOS Build & Deployment

### Step 1: Configure Xcode Project

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Runner" in the project navigator
3. Update the following:
   - **Display Name**: Group Manager
   - **Bundle Identifier**: com.groupmanager.groupManagerApp
   - **Version**: 1.0.0
   - **Build**: 1
   - **Deployment Target**: iOS 12.0 or higher

### Step 2: Configure Signing

1. In Xcode, go to "Signing & Capabilities"
2. Select your Apple Developer Team
3. Enable "Automatically manage signing"

### Step 3: Add App Icons

1. Create app icons (1024x1024 PNG)
2. Use a tool like [App Icon Generator](https://appicon.co/)
3. Add icons to `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Step 4: Build Release

```bash
flutter build ios --release
```

### Step 5: Archive and Upload

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as the build target
3. Go to **Product** → **Archive**
4. Once archived, click "Distribute App"
5. Select "App Store Connect"
6. Follow the wizard to upload

### Step 6: Submit to App Store

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Create a new app
3. Fill in app information:
   - App name: "Group Manager"
   - Category: Social Networking
   - Add screenshots (required for each device size)
   - Add app icon
   - Write description and keywords
4. Select the uploaded build
5. Submit for review

**Review time**: Usually 1-3 days

---

## Part 4: App Store Assets

### Screenshots Required

**Android (Play Store)**:
- Phone: 1080x1920 (minimum 2)
- 7-inch tablet: 1200x1920 (optional)
- 10-inch tablet: 1600x2560 (optional)

**iOS (App Store)**:
- 6.5" Display: 1284x2778 (iPhone 14 Pro Max)
- 5.5" Display: 1242x2208 (iPhone 8 Plus)
- 12.9" iPad Pro: 2048x2732

### App Icon
- **Android**: 512x512 PNG (no transparency)
- **iOS**: 1024x1024 PNG (no transparency, no rounded corners)

### Feature Graphic (Android)
- 1024x500 PNG

---

## Part 5: Testing Before Submission

### Android Testing
```bash
# Install release APK on device
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS Testing
Use TestFlight:
1. Upload build to App Store Connect
2. Add internal testers
3. Test thoroughly before public release

---

## Part 6: Post-Deployment

### Monitor Crashes
- **Android**: Google Play Console → Quality → Crashes
- **iOS**: App Store Connect → TestFlight/Analytics

### Update Firestore Rules
Switch from test mode to production rules (see FIREBASE_SETUP.md)

### Analytics (Optional)
Consider adding Firebase Analytics to track user engagement

---

## Common Issues

### Android Build Fails
- Ensure `minSdk = 21` in `build.gradle.kts`
- Run `flutter clean` and rebuild
- Check that `google-services.json` is in `android/app/`

### iOS Build Fails
- Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Run `pod install` in `ios/` directory
- Check that deployment target is iOS 12.0+

### Firebase Not Working
- Verify `flutterfire configure` was run
- Check that Firebase services are enabled in console
- Ensure `firebase_options.dart` exists

---

## Quick Reference Commands

```bash
# Check Flutter doctor
flutter doctor

# Clean build
flutter clean

# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Run on device
flutter run --release

# Check app size
flutter build apk --analyze-size
```

---

## Support & Resources

- [Flutter Deployment Docs](https://docs.flutter.dev/deployment)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com/)
