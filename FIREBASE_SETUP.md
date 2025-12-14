# Firebase Configuration Guide

This file will be auto-generated when you run the Firebase configuration command.

## Setup Instructions

1. Install Firebase CLI:
   ```
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```
   firebase login
   ```

3. Install FlutterFire CLI:
   ```
   dart pub global activate flutterfire_cli
   ```

4. Configure Firebase for your project:
   ```
   flutterfire configure
   ```

This will:
- Create a new Firebase project (or select an existing one)
- Register your Android and iOS apps
- Download the configuration files
- Generate `firebase_options.dart` automatically

## Manual Configuration (Alternative)

If you prefer to configure manually:

### Android Setup
1. Go to Firebase Console (https://console.firebase.google.com/)
2. Create a new project
3. Add an Android app with package name: `com.groupmanager.group_manager_app`
4. Download `google-services.json`
5. Place it in `android/app/`

### iOS Setup
1. In the same Firebase project, add an iOS app
2. Bundle ID: `com.groupmanager.groupManagerApp`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

### Enable Authentication
1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method

### Enable Firestore
1. In Firebase Console, go to Firestore Database
2. Click "Create Database"
3. Start in "Test Mode" (for development)
4. Choose your preferred region

### Enable Storage (Required for Dance Imposter Game)
1. In Firebase Console, go to Storage
2. Click "Get Started"
3. Start in "Test Mode"
4. Click "Done"

### Security Rules

#### Firestore Rules
Update Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /groups/{groupId} {
      allow read, write: if request.auth != null;
    }
    match /songs/{songId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Storage Rules
Update Storage rules in Firebase Console:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /songs/{groupId}/{songId}/{fileName} {
      allow read, write: if request.auth != null;
    }
  }
}
```
