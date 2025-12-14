# Group Manager App

A cross-platform mobile application for creating and managing groups with real-time member tracking.

## Features

- ✅ User registration with name, date of birth, and email
- ✅ Secure password-based authentication
- ✅ Create groups with unique 6-character IDs
- ✅ Join groups using group IDs
- ✅ Real-time member list updates
- ✅ Group creator identification
- ✅ Cross-platform support (Android & iOS)

## Tech Stack

- **Framework**: Flutter
- **Backend**: Firebase (Authentication + Firestore)
- **State Management**: Provider
- **Platform**: Android & iOS

## Getting Started

### Prerequisites

- Flutter SDK (3.1.0 or higher)
- Firebase account
- Android Studio / Xcode (for iOS)

### Installation

1. **Clone the repository**:
   ```bash
   cd g:\apk_dance-imposter
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   firebase login

   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Configure Firebase for your project
   flutterfire configure
   ```

4. **Enable Firebase services**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Enable **Authentication** → Email/Password
   - Enable **Firestore Database**
   - See `FIREBASE_SETUP.md` for detailed instructions

5. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── user_model.dart            # User data model
│   └── group_model.dart           # Group data model
├── services/
│   ├── auth_service.dart          # Authentication logic
│   └── group_service.dart         # Group management logic
├── screens/
│   ├── login_screen.dart          # Login page
│   ├── registration_screen.dart   # Signup page
│   ├── home_screen.dart           # Main dashboard
│   ├── create_group_screen.dart   # Create group flow
│   ├── join_group_screen.dart     # Join group flow
│   └── group_members_screen.dart  # Member list view
└── widgets/
    ├── custom_button.dart         # Reusable button
    └── custom_text_field.dart     # Reusable input field
```

## How It Works

### User Flow

1. **Registration**: New users sign up with name, DOB, email, and password
2. **Login**: Returning users log in with email and password
3. **Home Screen**: Choose to create a new group or join an existing one
4. **Create Group**: Generate a unique 6-character ID to share with others
5. **Join Group**: Enter a group ID to join an existing group
6. **View Members**: Group creators can see all members in real-time

### Firebase Structure

**Firestore Collections**:

```
users/
  {userId}/
    - name: string
    - dob: timestamp
    - email: string
    - createdAt: timestamp
    - groupIds: array

groups/
  {groupId}/
    - groupId: string (6 characters)
    - creatorId: string
    - creatorName: string
    - members: array
      - userId: string
      - name: string
      - joinedAt: timestamp
    - createdAt: timestamp
```

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

See `DEPLOYMENT_GUIDE.md` for detailed deployment instructions.

## Configuration Files

- `FIREBASE_SETUP.md` - Firebase configuration guide
- `DEPLOYMENT_GUIDE.md` - App store deployment guide
- `pubspec.yaml` - Dependencies and app metadata

## Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Firebase not initialized**: Run `flutterfire configure`
2. **Build fails**: Run `flutter clean` then `flutter pub get`
3. **Android minSdk error**: Ensure `minSdk = 21` in `android/app/build.gradle.kts`

### Getting Help

- Check `FIREBASE_SETUP.md` for Firebase configuration
- Check `DEPLOYMENT_GUIDE.md` for deployment issues
- Run `flutter doctor` to diagnose environment issues

## License

This project is created for educational and personal use.

## Next Steps

- [ ] Run `flutterfire configure` to set up Firebase
- [ ] Test the app on Android/iOS emulator
- [ ] Configure app icons and splash screens
- [ ] Deploy to Play Store and App Store

---

**Built with Flutter 💙**
# apkDanceImposter
