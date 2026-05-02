# Force Fitness (GymMate)

A modern personal training companion built with Flutter and Firebase. Plan routines, log workouts, track PRs, steps/water/sleep, and visualize your progress across platforms.

## Table of contents
- Overview
- Features
- Architecture
- Tech stack
- Project structure
- Getting started
- Firebase configuration
- Running and building
- Configuration and environment
- Troubleshooting
- Contributing
- License

## Overview
Force Fitness (a.k.a. GymMate) is a cross‑platform fitness app designed to help you stay consistent. It combines streamlined workout logging with weekly goals, progress insights, and a clean, motivating UI.

## Features
- Authentication & Onboarding
  - Google Sign‑In and Email/Password via Firebase Auth
  - Onboarding with profile seeding and preferred name
  - Edge‑to‑edge login screen with background image and session safety (prevents stale redirects)
- Dashboard
  - Welcome card with your name and daily context
  - Quick actions: add steps, water, log sleep (writes to selected day)
  - Weekly goals: steps, water (ml), sleep (min), workouts — animated rings that update in real time
- Logger & Routines
  - Start a workout from scratch or from a routine
  - Warm‑up generator and editable sets (reps, weight)
  - Routine editor (create/edit/duplicate, reorder exercises, add/remove sets)
  - "Load today’s split" preserves custom exercises
- Exercises
  - Exercise library with search, plus custom exercises you can create and edit
- Personal Records (PRs) & Charts
  - Detects and saves best‑set PRs and running PRs on session save
  - Sortable PR tracker and progress charts
- Progress Tracking
  - Progress photos with dates and notes
  - Body measurements (e.g., weight, chest, waist, arms, hips, thighs)
- Activity Tracking
  - Steps, water (ml), sleep (minutes) logging with daily targets
  - Weekly aggregation via range streams; updates reflect across Dashboard and Nutrition instantly
- GPS Run Tracker
  - Live GPS tracking using device location (start/pause/resume/stop)
  - Metrics: distance, duration, current/average pace
  - Route polyline map preview; save run as part of history
- Nutrition
  - Daily macro goals and summaries
  - Barcode scanning via camera to look up foods
  - Manual food entry/edit (servings and macros)
  - Hydration summary with quick‑add water
- Sharing
  - Share progress (e.g., run summaries or screenshots) via the device share sheet
- Profile & Goals
  - Edit display name and daily/weekly goals; changes reflect immediately across the app

## Architecture
- Flutter 3 (Dart 3)
- State management: Provider
- Firebase: Auth, Firestore, Storage
- Repository pattern per domain (Steps, Water, Sleep, Workout, Routines, etc.)
  - Real‑time streams for day and range queries (e.g., weekly aggregation)
- Routing: `AuthGate` decides between onboarding or the main shell
- UI tabs: Dashboard, Logger, Exercises, Nutrition, Profile
- Animated rings: custom painter for smooth weekly goal visuals

## Tech stack
- Flutter SDK (stable channel)
- Dart >= 3.8
- Firebase (Auth, Firestore, Storage)
- Packages: provider, google_sign_in, firebase_* packages, fl_chart, image_picker, mobile_scanner, google_fonts, etc.

## Project structure
```
lib/
  firebase_options.dart        # FlutterFire options (if using CLI)
  main.dart
  models/                      # Data models (steps, sleep, water, routines, etc.)
  services/                    # Repositories & Firebase wiring
  ui/
    screens/                   # Screens grouped by feature
    widgets/                   # Reusable widgets
assets/                        # Seed data (e.g., exercises)
images/                        # App imagery (backgrounds, logos, etc.)
android/ ios/ macos/ linux/ web/ windows/   # Platform scaffolding
```

## Getting started
Prerequisites
- Flutter SDK installed and on PATH
- Android Studio (for Android) and/or Xcode (for iOS)
- A Firebase project with Android/iOS apps registered
- Dart 3.8+

Install dependencies
```
flutter pub get
```

Configure Firebase
- Android: place `google-services.json` in `android/app/`
- iOS: place `GoogleService-Info.plist` in `ios/Runner/`
- If using FlutterFire CLI, ensure `lib/firebase_options.dart` is up to date and `Firebase.initializeApp()` uses it.

Run the app
```
flutter run
```

Analyze (recommended during development)
```
flutter analyze
```

## Firebase configuration
High‑level Firestore model
- `users/{uid}`: profile (displayName, onboarded, daily/weekly goals)
- `steps/{uid}/entries/{dateISO}`: steps count
- `water/{uid}/entries/{dateISO}`: ml
- `sleep/{uid}/entries/{dateISO}`: minutes
- `workouts/{uid}/sessions/{sessionId}`: exercises -> sets/reps/weight
- `routines/{uid}/{routineId}`: routine template with exercises & default sets
- Progress (photos, measurements, PRs) stored similarly per user

Security rules
- Lock down reads/writes by `request.auth.uid == resource.data.uid` equivalents
- Consider per‑collection granular rules for production

## Running and building
Run on a connected device/emulator
```
flutter run -d <device_id>
```

Build Android APK
```
flutter build apk --release
```

Build iOS (requires macOS/Xcode)
```
flutter build ios --release
```

## Feature details and permissions

Permissions used
- Camera: barcode scanning for nutrition and progress photo capture
- Location: GPS run tracking (distance/route/pace)
- Internet/Network: Firebase connectivity and nutrition lookup

Feature notes
- Real‑time updates: Weekly rings and most lists reflect Firestore changes instantly
- Routines: Start a routine to prefill the logger; reorder exercises and sets before starting
- PR logic: Best‑set and running PRs are computed and persisted when saving sessions
- Nutrition scanning: Uses barcode (via device camera); manual entry is available for custom foods
- Run tracker: Designed for outdoor use; accuracy depends on device hardware, signal, and settings

## Configuration and environment
- App name, icons, and package IDs live in `android/` and `ios/` folders
- Firebase project settings come from the platform files above and `firebase_options.dart`
- Secrets (service files) should not be committed to source control

## Troubleshooting
- Android build fails with "Unsupported class file major version"
  - Ensure you are using a supported JDK (Java 17 or 21 are safe choices for recent Android Gradle Plugin)
  - Set `JAVA_HOME` to that JDK and restart your terminal/IDE
- Firebase initialization errors
  - Confirm `google-services.json` / `GoogleService-Info.plist` are present and match the app id
  - Verify `firebase_options.dart` if using FlutterFire CLI
- Google sign‑in shows previous account
  - The app signs out stale sessions before new sign‑in; uninstalling and reinstalling can also reset test devices

## Contributing
1. Create a feature branch from `main`
2. Keep PRs focused and include screenshots/GIFs for UI changes
3. Add or update small tests if public behavior changes

## License
This codebase is provided for personal/portfolio use. If you plan to publish or redistribute, add a clear LICENSE file and verify third‑party asset licenses.
