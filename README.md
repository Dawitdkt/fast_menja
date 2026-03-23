# Fast Menja - Driving Theory Test Mobile App

A comprehensive Flutter application for UK learner drivers, featuring four study modes: theory questions, hazard perception, mock tests, and interactive lessons. Built with clean architecture principles, offline-first design, and Firebase integration.

## ✨ What's Implemented

### ✅ Core Architecture
- **Repository Pattern** with clear separation of concerns
- **Riverpod 2.5** for state management and dependency injection
- **Go Router** for declarative navigation
- **Clean Architecture** with features, domain, data, and UI layers

### ✅ Features
1. **Lessons Module**
   - Markdown-based lessons bundled with the app
   - YAML frontmatter metadata
   - Progress tracking (completed, bookmarked)
   - Reading time estimates
   - Offline-first

2. **Quiz Engine**
   - Theory practice mode (unlimited theory questions)
   - Mock tests (50 questions, 57 minutes, official DVSA format)
   - Road signs quiz
   - Spaced repetition for weak questions
   - Question explanations
   - Score tracking

3. **Authentication**
   - Email/password authentication
   - Google Sign-In
   - Apple Sign-In
   - Guest mode with seamless migration to accounts
   - Anonymous auth via Firebase

4. **Data Persistence**
   - Hive for local offline storage (lessons, questions, progress)
   - Cloud Firestore for user data sync
   - Offline-first architecture with automatic sync
   - Local progress preserved across sessions

5. **Premium Monetization**
   - RevenueCat integration
   - Freemium model with clear feature gating
   - Support for iOS App Store and Google Play
   - Premium entitlements and subscription management

### ✅ Services & Integrations
- **Firebase Authentication** (Email, Google, Apple, Anonymous)
- **Cloud Firestore** with offline persistence
- **Firebase Cloud Functions** for server-side logic
- **Firebase Remote Config** for feature gates and content updates
- **Firebase Cloud Messaging** for push notifications
- **RevenueCat** for subscription management

### ✅ Data Models
- Lesson metadata and progress
- Question bank with categories
- User profiles with premium status
- Quiz sessions and mock test results
- Weak question tracking for spaced repetition
- Quiz statistics by category

### ✅ UI Screens
- Dashboard/Home screen with navigation
- Lesson list with category grouping
- Lesson reader with markdown rendering
- Theory quiz screen with instant feedback
- Mock test screen with timer
- Profile screen with statistics
- Login/registration screen
- Hazard perception placeholder

### ✅ Backend Infrastructure
- **Firestore Rules** for secure database access
- **Storage Rules** for video access control
- **Cloud Functions** for user creation, reminders, and stats aggregation
- **firebase.json** configuration

### ✅ Content Pipeline
- 3 sample lessons in Markdown format
- 10 sample questions covering multiple categories
- Lessons index for efficient loading
- Tools for adding new content without code changes

### ✅ Documentation
- Comprehensive implementation guide
- Firebase & RevenueCat setup instructions
- Project structure documentation
- API references

## 📋 Quick Start

### Prerequisites
- Flutter 3.0+ and Dart 3.0+
- Firebase account
- RevenueCat account (for payments)

### Setup Steps

1. **Clone and install dependencies**
   ```bash
   cd fast_menja
   flutter pub get
   flutter pub run build_runner build
   ```

2. **Configure Firebase**
   - Download credentials from Firebase Console
   - Update `lib/firebase_options.dart`
   - See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions

3. **Configure RevenueCat**
   - Set up products and entitlements
   - Add API key to firebase_options.dart

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── models/          User and stats models
│   ├── services/        Auth, Firestore, Local storage
│   ├── providers/       Riverpod state management
│   ├── navigation/      Go Router configuration
│   └── utils/           Extensions, algorithms
├── features/
│   ├── lessons/         Lesson reading and progress
│   ├── quiz/            Theory, mock tests, scoring
│   ├── auth/            Authentication UI
│   ├── hazard/          Hazard perception (premium)
│   └── profile/         User profile and stats
└── main.dart            App entry point

assets/
├── lessons/             Markdown lesson files
├── questions.json       Question bank (1000+ questions)
└── lessons_index.json   Lesson metadata index

functions/               Firebase Cloud Functions
firestore.rules         Firestore security rules
storage.rules           Firebase Storage rules
```

## 🔧 Key Technologies

| Layer | Technology |
|-------|-----------|
| **State Management** | Riverpod |
| **Navigation** | Go Router |
| **Local Storage** | Hive |
| **Database** | Cloud Firestore |
| **Authentication** | Firebase Auth |
| **Payments** | RevenueCat |
| **Content Rendering** | flutter_markdown |
| **Video** | video_player, cached_network_image |

## 📚 Documentation

- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Complete implementation details
- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Firebase and RevenueCat configuration
- **[System Design Document](system-design-document.docx)** - Architecture overview

## 🔐 Security

- User data encrypted at rest
- Firestore security rules restrict access to user's own data
- RevenueCat handles subscription validation
- API keys stored in environment variables
- Anonymous auth for guests

## 🚀 Deployment

### Android
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

### iOS
```bash
flutter build ios --release
# Upload to App Store Connect
```

### Firebase
```bash
firebase deploy --only firestore:rules,storage:rules,functions
```

## 📈 Features & Roadmap

### Current (v1.0)
- ✅ Theory questions
- ✅ Mock tests
- ✅ Lesson content
- ✅ Offline access
- ✅ User accounts
- ✅ Premium subscriptions
- ✅ Progress syncing

### Future Enhancements
- [ ] Leaderboards
- [ ] AI explanations
- [ ] Web version
- [ ] Admin dashboard
- [ ] Welsh language
- [ ] Dark mode
- [ ] Push notifications

## 📞 Support

For issues, refer to:
1. FIREBASE_SETUP.md for Firebase questions
2. IMPLEMENTATION_GUIDE.md for project structure
3. Code comments for specific implementations

## 📄 License

© 2026 Fast Menja. All rights reserved.