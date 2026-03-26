# Fast Menja - Driving Theory Test 4-in-1 Mobile App

A Flutter-based mobile application for UK learner drivers, covering four core study modes: theory questions, hazard perception, mock tests, and lesson content.

## Project Overview

**Platform:** iOS + Android (Flutter)  
**Status:** v1.0 - Supabase Migration In Progress  
**Architecture:** Clean Architecture + Riverpod + Repository Pattern  
**Database:** Supabase Postgres + Hive (offline-first)  
**Monetization:** RevenueCat (Freemium model)  

## Quick Start

### Prerequisites

- Flutter 3.0+ SDK
- Dart 3.0+
- Supabase CLI
- Xcode 14+ (for iOS)
- Android Studio (for Android)

### Installation

1. **Clone and setup**
```bash
cd fast_menja
flutter pub get
```

2. **Configure Supabase**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to `.env`
   - Apply SQL migrations from `supabase/migrations/`

3. **Configure RevenueCat**
   - Sign up at [revenuecat.com](https://revenuecat.com)
   - Get your API key
   - Add to `.env` file

4. **Generate code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. **Run the app**
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── models/              # User, Stats models
│   ├── services/            # Auth, Firestore, Local Storage
│   ├── providers/           # Riverpod providers
│   ├── navigation/          # Go Router config
│   └── utils/               # Extensions, Spaced Repetition
├── features/
│   ├── lessons/
│   │   ├── data/            # Lesson Repository
│   │   ├── domain/          # Lesson Models
│   │   └── ui/              # Screens
│   ├── quiz/
│   │   ├── data/            # Quiz Repository
│   │   ├── domain/          # Question Models
│   │   └── ui/              # Screens
│   ├── auth/
│   │   └── ui/              # Login/Register screens
│   ├── hazard/
│   │   └── ui/              # Hazard Perception screens
│   └── profile/
│       └── ui/              # Profile screen
└── main.dart

assets/
├── lessons/                 # Markdown lesson files
├── questions.json           # Question bank
└── lessons_index.json       # Lesson index metadata
```

## Key Features

### 1. Lessons (Offline-First)
- Markdown-based lessons bundled at build time
- YAML frontmatter for metadata
- Progress tracking (completed, bookmarked)
- Reading time estimates

### 2. Theory Practice
- Unlimited theory questions (free)
- Category-based filtering
- Spaced repetition for weak questions
- Instant feedback with explanations

### 3. Mock Tests
- 50 questions, 57 minutes
- Pass mark: 43/50 (86%)
- Official DVSA format
- Review after completion
- Premium feature (1/day free, unlimited for premium)

### 4. Hazard Perception
- Video-based hazard training
- Premium feature
- Cached for offline viewing

### 5. Authentication & Sync
- Email/password, Google, Apple sign-in
- Guest mode with migration to accounts
- Cloud sync via Firestore
- Offline-first with automatic sync

### 6. Premium Monetization
- RevenueCat integration
- Freemium model with clear feature gates
- Apple App Store & Google Play support

## State Management

Uses **Riverpod 2.5** for:
- Dependency injection
- Reactive state management
- Async data handling
- Auth state stream

### Core Providers

```dart
// Auth
authStateProvider          // Firebase Auth stream
isSignedInProvider        // Is user logged in?
currentUserProvider       // Current Firebase User
userProfileProvider       // User Firestore document

// Lessons
lessonIndexProvider       // All lessons metadata
lessonBySlugProvider      // Single lesson markdown
lessonProgressProvider    // Notifier for progress

// Quiz
quizSessionProvider       // Current quiz state
questionProvider          // Individual question
weakQuestionsProvider     // Due for spaced repetition
mockTestResultsProvider   // Past test results

// Stats
completedLessonsCountProvider
bookmarkedLessonsProvider
isPremiumProvider
```

## Data Models

### Firestore Schema
```
users/{uid}
  ├── displayName, email, createdAt, isPremium
  ├── fcmToken
  └── subcollections:
      ├── progress/{lessonSlug} - lesson completion state
      ├── quizStats/{category} - category statistics
      ├── weakQuestions/{questionId} - spaced repetition data
      └── mockTests/{testId} - test results
```

### Local Storage (Hive)
- `lesson_progress` - Lesson completion state
- `questions` - Question bank cache
- `weak_questions` - Spaced repetition queue
- `mock_tests` - Test results cache

## Content Pipeline

### Adding Lessons
1. Create `assets/lessons/XX-slug.md` with YAML frontmatter
2. Update `assets/lessons_index.json`
3. Run `flutter build` to bundle

### Frontmatter Format
```yaml
---
slug: unique-identifier
title: Lesson Title
category: Category Name
order: 1
readingTimeMinutes: 5
tags: [tag1, tag2]
---

## Lesson Content
...
```

### Adding Questions
1. Update `assets/questions.json` with new questions
2. Use Remote Config to push updates without app release

## Spaced Repetition Algorithm

Simplified SM-2 implementation:
- Incorrect count determines next due date
- Intervals: 1, 2, 4, 7, 14, 30 days
- Questions due today are prioritized in review

```dart
DateTime nextDueDate(int incorrectCount) {
  const intervals = [1, 2, 4, 7, 14, 30];
  final idx = incorrectCount.clamp(0, intervals.length - 1);
  return DateTime.now().add(Duration(days: intervals[idx]));
}
```

## Firebase Setup

### Firestore Rules
```
- Users can only read/write their own documents
- Weak questions queries filtered by nextDueAt < now()
- Anonymous auth enabled for guests
- Offline persistence enabled
```

### Security
- No API keys in code (use .env)
- RevenueCat webhook validation
- Firebase custom claims for premium verification

## Deployment

### Android
```bash
# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# Build IPA for TestFlight
flutter build ios --release

# Or use Xcode
open ios/Runner.xcworkspace
```

### Supabase Deployment
```bash
# Push database migrations
supabase db push

# Deploy edge functions
supabase functions deploy create-user-profile
supabase functions deploy validate-premium
supabase functions deploy send-daily-reminder
supabase functions deploy aggregate-stats
```

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Check code quality
dart analyze
```

## Performance Optimization

- Question bank cached locally after first load
- Hive for fast key-value operations
- Firestore offline persistence enabled
- Lazy loading of lesson content
- Firebase Remote Config for feature gates

## Future Enhancements

- [ ] Leaderboard & competitive streaks
- [ ] AI-generated question explanations
- [ ] Web version (Flutter Web)
- [ ] Admin dashboard (Retool)
- [ ] Welsh language support
- [ ] Accessibility improvements
- [ ] Push notification reminders
- [ ] Dark mode support

## Environment Variables

Create `.env`:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_WEB_API_KEY=your-key
FIREBASE_ANDROID_API_KEY=your-key
FIREBASE_IOS_API_KEY=your-key
REVENUE_CAT_API_KEY=your-key
ENVIRONMENT=development
```

## Dependencies

See `pubspec.yaml` for complete list. Key packages:
- **flutter_riverpod** - State management
- **go_router** - Navigation
- **hive_flutter** - Local storage
- **supabase_flutter** - Auth and cloud database
- **flutter_markdown** - Content rendering
- **purchases_flutter** - RevenueCat billing

## Support & Contact

For issues, questions, or contributions, please refer to the system design document and architecture.

## License

© 2026 Fast Menja. All rights reserved.

---

**Last Updated:** March 2026  
**Version:** 1.0.0
