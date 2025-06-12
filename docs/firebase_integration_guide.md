# Firebase Integration Guide for TatkalPro

This document provides a comprehensive reference for the Firebase integration in the TatkalPro app, including setup steps, configuration details, and troubleshooting tips.

## Table of Contents
1. [Firebase Project Setup](#firebase-project-setup)
2. [Flutter App Integration](#flutter-app-integration)
3. [Platform-Specific Configuration](#platform-specific-configuration)
4. [Push Notification Implementation](#push-notification-implementation)
5. [Backend Integration](#backend-integration)
6. [Troubleshooting](#troubleshooting)
7. [Useful Commands](#useful-commands)

## Firebase Project Setup

### Project Configuration
- **Project Name**: TatkalPro
- **Project ID**: tatkalpro-14fdd
- **Web API Key**: AIzaSyCxBDunIyTmmnV3GtlgQr0YLOeATHDFfbw
- **Android API Key**: AIzaSyBZVQYjCnrQUsbVH46s7dliBkrCohytFtk
- **iOS API Key**: AIzaSyBZVQYjCnrQUsbVH46s7dliBkrCohytFtk

### Services Enabled
- Firebase Cloud Messaging (FCM)
- Firebase Authentication
- Firebase Storage

## Flutter App Integration

### Required Dependencies
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.6.7
  flutter_local_notifications: ^15.1.1
  js: ^0.6.5
```

### Installation Commands
```bash
# Add Firebase Core and Messaging packages
flutter pub add firebase_core firebase_messaging

# Get all dependencies
flutter pub get
```

### Firebase Configuration Files
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Web**: Firebase configuration in `firebase_options.dart`

## Platform-Specific Configuration

### Web Platform
- Created stub implementations to handle web platform limitations
- Files:
  - `firebase_options_web.dart`: Empty Firebase options for web
  - `firebase_stub.dart`: Stub implementations for Firebase classes
  - `notification_service_web.dart`: Web-specific notification service

### Android Platform
- Added Firebase configuration in `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

- Added classpath in `android/build.gradle`:
```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
```

### iOS Platform
- Added Firebase initialization in `ios/Runner/AppDelegate.swift`
- Added required capabilities in Xcode project:
  - Push Notifications
  - Background Modes > Remote notifications

## Push Notification Implementation

### Initialization in `main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on mobile platforms
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize notification service only on mobile platforms
    await NotificationService().initialize();
  } else {
    print('Running on web platform - Firebase initialization skipped');
  }
  
  runApp(/* ... */);
}
```

### Notification Service Implementation
- Created a dedicated `NotificationService` class
- Implemented handlers for:
  - Background messages
  - Foreground messages
  - Notification taps
- Added platform-specific code with `kIsWeb` checks

### FCM Token Registration
- Implemented in `UserService.registerFcmToken()`
- Token is sent to backend API for storage
- Added platform check to skip registration on web

## Backend Integration

### Firebase Admin SDK
- Deployed on AWS Lambda with name "tatkalpro-backend"
- Used base64-encoded credentials for secure storage
- Implemented push notification sending functionality

### Notification Types
1. **Booking Updates**: Sent when booking status changes
2. **Payment Notifications**: Sent for successful/failed payments
3. **System Alerts**: Important system-wide announcements

## Troubleshooting

### Common Issues and Solutions

1. **Package Resolution Issues**
   - **Problem**: "Couldn't resolve the package 'firebase_core'"
   - **Solution**: Run `flutter pub get` to install dependencies

2. **Firebase Initialization Errors**
   - **Problem**: "Firebase has not been correctly initialized"
   - **Solution**: Ensure `Firebase.initializeApp()` is called before using any Firebase services

3. **Web Platform Errors**
   - **Problem**: Missing types like `PromiseJsImpl`, undefined methods
   - **Solution**: Use conditional imports and stub implementations for web

4. **Version Compatibility Issues**
   - **Problem**: Incompatible versions between Firebase packages
   - **Solution**: Use compatible versions (`firebase_messaging: ^14.6.7` with `js: ^0.6.5`)

## Useful Commands

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure

# Run app in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle

# Clean build cache
flutter clean

# Update Firebase packages
flutter pub upgrade firebase_core firebase_messaging
```

---

*Last Updated: June 12, 2025*
