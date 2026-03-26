# Firebase & RevenueCat Setup Guide

## Firebase Project Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create Project"
3. Name it "fast-menja" (or similar)
4. Disable Google Analytics (optional)

### 2. Enable Firebase Services

#### Authentication
1. In Firebase Console → Authentication → Sign-in method
2. Enable:
   - Email/Password
   - Google Sign-In
   - Apple Sign-In
   - Anonymous

#### Cloud Firestore
1. Firestore Database → Create Database
2. Choose region closest to users (e.g., `europe-west1`)
3. Start in **production mode** (use rules below)

#### Security Rules
Apply these Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == uid;
    }
  }
}
```

#### Storage
1. Cloud Storage → Create Bucket
2. Location: Same as Firestore
3. Apply storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /hazard/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
  }
}
```

#### Cloud Functions
1. Cloud Functions → Create Function
2. Deploy the functions from `functions/index.js`
3. Set 2nd gen runtime, 512MB memory, 60s timeout

### 3. Get Firebase Credentials

#### Android
1. Firebase Console → Project Settings → Android
2. Download `google-services.json`
3. Place in `android/app/`

#### iOS
1. Firebase Console → Project Settings → iOS
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/` via Xcode (Add Files → Create folder ref)

### 4. Update Credentials in Code

Edit `lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY', // From google-services.json
  appId: '1:PROJECT_NUMBER:android:APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY', // From GoogleService-Info.plist
  appId: '1:PROJECT_NUMBER:ios:APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
  iosBundleId: 'com.example.fast_menja',
);
```

## RevenueCat Setup

### 1. Create RevenueCat Account

1. Go to [revenuecat.com](https://revenuecat.com)
2. Sign up and create a new project
3. Name it "Fast Menja"

### 2. Configure Products

#### Create Subscriptions

**Monthly Premium:**
- ID: `premium_monthly_999`
- Display name: "Premium Monthly"
- Price: $9.99/month

**Annual Premium:**
- ID: `premium_annual_7999`
- Display name: "Premium Annual"
- Price: $79.99/year

**Entitlement:**
- Create entitlement: `premium`
- Add both subscriptions to it

### 3. Connect to App Stores

#### Apple App Store
1. In RevenueCat → Apple App Store
2. Add your app and shared secret (from App Store Connect)
3. Add the subscription products

#### Google Play
1. In RevenueCat → Google Play
2. Add your app and API key (from Google Play Console)
3. Add the subscription products

### 4. Android Implementation

Update `android/app/build.gradle`:

```gradle
dependencies {
  // RevenueCat already in pubspec.yaml
  implementation 'com.revenuecat.purchases:purchases:7.+'
}
```

### 5. iOS Implementation

No extra setup needed beyond pubspec.yaml, but ensure:
- StoreKit 2 is enabled in Xcode Capabilities
- SKUDetailsConnection is setup in iOS deployment target

### 6. Configure in Flutter

In `lib/core/services/auth_service.dart` or main:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> initializeRevenueCat() async {
  await Purchases.configure(
    PurchasesConfiguration(
      'YOUR_REVENUE_CAT_API_KEY',
    ),
  );
}
```

Check subscription:

```dart
final customerInfo = await Purchases.getCustomerInfo();
final isPremium = customerInfo.entitlements.active.containsKey('premium');
```

### 7. Update Premium Check

In `lib/core/providers/app_providers.dart`:

```dart
final isPremiumProvider = FutureProvider<bool>((ref) async {
  try {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey('premium');
  } catch (e) {
    // Fallback to Firestore
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;
    final profile = await ref.watch(userProfileProvider.future);
    return profile?.isPremium ?? false;
  }
});
```

## Firestore Schema Reference

### collections/users
Document ID: Firebase UID

```json
{
  "displayName": "John Doe",
  "email": "john@example.com",
  "createdAt": "2026-03-20T10:00:00Z",
  "isPremium": false,
  "fcmToken": "firebase-messaging-token",
  "lastSignIn": "2026-03-23T15:00:00Z"
}
```

### collections/users/{uid}/progress
Document ID: lesson slug

```json
{
  "slug": "road-signs-warning",
  "completed": true,
  "bookmarked": false,
  "completedAt": "2026-03-22T14:30:00Z"
}
```

### collections/users/{uid}/quizStats
Document ID: category name

```json
{
  "category": "road-signs",
  "totalAttempts": 12,
  "totalCorrect": 10,
  "lastAttemptAt": "2026-03-23T11:00:00Z"
}
```

### collections/users/{uid}/weakQuestions
Document ID: question ID

```json
{
  "questionId": "q001",
  "incorrectCount": 3,
  "lastSeenAt": "2026-03-23T10:00:00Z",
  "nextDueAt": "2026-03-30T10:00:00Z"
}
```

### collections/users/{uid}/mockTests
Document ID: test ID (UUID)

```json
{
  "testId": "uuid-here",
  "score": 45,
  "totalQuestions": 50,
  "passedAt": "2026-03-23T09:00:00Z",
  "durationSeconds": 3420,
  "passed": true
}
```

## Cloud Functions Deployment

```bash
cd functions
npm install
cd ..

firebase deploy --only functions
```

### Environment Variables for Functions

Set via Firebase Console:

```
REVENUECAT_API_KEY=<api-key>
SENDGRID_API_KEY=<email-key>  # Optional for email notifications
```

## Testing Locally

### Firestore Emulator
```bash
firebase emulators:start --only firestore,auth
```

Update `lib/main.dart`:
```dart
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

### RevenueCat Sandbox
- iOS: App Store Sandbox tester account
- Android: Use Google Play Console internal testing track

## Monitoring & Debugging

### Firebase Console
- Authentication → Sign-in methods activity
- Firestore → Rules tests
- Cloud Functions → Logs and errors
- Storage → Usage and activity

### RevenueCat Dashboard
- Customer list and subscription status
- Revenue charts
- Churn analysis
- Integration status

## Common Issues

**Firebase initialization error**
- Ensure google-services.json and GoogleService-Info.plist are in correct locations
- Check Bundle ID matches Firebase project

**Firestore permission denied**
- Verify security rules are applied
- Check user is authenticated
- Test rules in Firebase Console

**RevenueCat not registering premium**
- Verify products are published in App Store/Play Store
- Check RevenueCat API key is correct
- Test with sandbox account

## Next Steps

1. ✅ Create Firebase project
2. ✅ Enable services and get credentials
3. ✅ Update firebase_options.dart
4. ✅ Deploy Firestore and Storage rules
5. ✅ Deploy Cloud Functions
6. ✅ Set up RevenueCat account
7. ✅ Configure products and entitlements
8. ✅ Update Flutter code with API keys
9. ✅ Test authentication and payments
10. ✅ Deploy to App Stores
