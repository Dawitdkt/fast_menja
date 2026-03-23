# Fast Menja - Troubleshooting Guide

## Common Issues & Solutions

### Build Issues

#### "flutter pub get" fails
**Problem:** Pub get hangs or fails with timeout
**Solutions:**
1. Clear pub cache: `flutter pub cache repair`
2. Use different pub mirror:
   ```bash
   export PUB_HOSTED_URL=https://pub.flutter-io.cn
   export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
   flutter pub get
   ```
3. Check internet connection

#### Build runner not generating files
**Problem:** Files like `lesson_model.g.dart` not generated
**Solutions:**
1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
2. Check for syntax errors in models
3. Verify `part ''` directive exists in model files

#### "google-services.json not found"
**Problem:** Android build fails
**Solutions:**
1. Download from Firebase Console
2. Place in `android/app/google-services.json`
3. Rebuild: `flutter clean && flutter pub get`

### Runtime Issues

#### Firebase initialization fails
**Problem:** "PlatformException: PERMISSION_DENIED"
**Solutions:**
1. Check Firebase credentials in `firebase_options.dart`
2. Verify Firebase project exists
3. Check iOS/Android bundle IDs match Firebase config
4. For iOS, ensure GoogleService-Info.plist is added via Xcode (not manual file creation)

#### "Can't find Hive box" error
**Problem:** App crashes trying to access Hive storage
**Solutions:**
1. Ensure `LocalStorageService().init()` called before using boxes
2. Check models have `@HiveType` annotations
3. Clear app data: `flutter clean`
4. Delete Hive database: `rm -rf ~/Library/Developer/Xcode/DerivedData/`

#### Firestore offline persistence not working
**Problem:** Data not persisting locally
**Solutions:**
1. Ensure `FirestoreService.enableOfflinePersistence()` is called
2. Check Firestore rules allow read/write for authenticated users
3. Verify user is signed in when trying to sync
4. Check available storage space on device

### Feature Issues

#### Quiz timer not counting down
**Problem:** Timer stays at same value
**Solutions:**
1. Ensure `_startTimer()` is called
2. Check `Timer.periodic` is not already running
3. Verify Riverpod provider is updating state
4. Check if app goes to background (timer stops)

#### Questions not loading
**Problem:** "Question not found" error
**Solutions:**
1. Verify `assets/questions.json` exists
2. Check Hive box was initialized: `await localStorage.loadQuestionsFromAssets()`
3. Ensure `pubspec.yaml` includes questions.json in assets
4. Run `flutter clean` and rebuild

#### Progress not syncing to Firestore
**Problem:** Local progress saved but not in Firestore
**Solutions:**
1. Verify user is signed in (not guest)
2. Check Firestore security rules allow write
3. Ensure network connectivity
4. Check user has subcollection `progress` created
5. Force sync: `await firestoreService.updateUserProfile(uid, {})`

#### Lessons not displaying
**Problem:** Lesson reader shows blank
**Solutions:**
1. Verify lesson slug matches file name (without .md)
2. Check `assets/lessons/[slug].md` file exists
3. Ensure YAML frontmatter is valid
4. Verify `assets/lessons_index.json` includes lesson
5. Clear app cache: `flutter clean`

### Authentication Issues

#### Google Sign-In not working
**Problem:** GoogleSignIn returns null or error
**Solutions:**
1. **Android:**
   - Get SHA-1: `./gradlew signingReport`
   - Add to Firebase Console → Android settings
   - Ensure google-services.json is updated

2. **iOS:**
   - Add URL scheme to GoogleService-Info.plist
   - Check Bundle ID in Xcode matches Firebase config
   - Ensure iOS signing certificate is valid

#### Apple Sign-In fails on Android
**Problem:** "Method not available"
**Solutions:**
- Apple Sign-In is iOS only
- On Android, remove or disable Apple option
- Check `sign_in_with_apple` package documentation

#### Guest-to-account migration not working
**Problem:** Progress lost when signing in
**Solutions:**
1. Ensure local progress was saved before sign-in
2. Check `mergeProgressAfterSignIn()` is called
3. Verify Firestore document was created for new user
4. Check network connectivity during merge
5. Try sign-in again after ensuring online

### Performance Issues

#### App is slow after loading questions
**Problem:** Noticeable lag when opening quiz
**Solutions:**
1. First load is slower - this is normal
2. Subsequent loads use Hive cache - should be instant
3. Reduce question count if still slow
4. Check device storage isn't full
5. Close other apps to free memory

#### High battery usage when offline
**Problem:** Battery drains quickly
**Solutions:**
1. Firestore offline persistence is safe - designed for this
2. Disable background sync if not needed
3. Quiz timer only active during sessions
4. Check no infinite loops in providers
5. Profile with Android Studio / Xcode

#### Consistent "out of memory" crashes
**Problem:** App crashes with memory errors
**Solutions:**
1. Check Hive cache size: shouldn't exceed 50MB
2. Reduce question bank size if very large (10k+)
3. Check for memory leaks in StreamListeners
4. Close unused Hive boxes
5. Monitor with DevTools memoria profiler

### Data Issues

#### Firestore rules rejected my write
**Problem:** FirebaseException: permission-denied
**Solutions:**
1. Check rule allows user's UID
2. Verify user is authenticated (not anonymous guest)
3. Check document path matches rule pattern
4. Test rules in Firebase Console Simulator
5. Enable Firestore debug logging to see which rule failed

#### Question correct answer is wrong
**Problem:** Marking incorrect answers as correct
**Solutions:**
1. Verify `correctIndex` in `questions.json` is 0-3
2. Check answers array has exactly 4 items
3. Verify index matches actual correct answer
4. Test with Remote Config override

#### Progress disappears after app restart
**Problem:** Reset progress on app close
**Solutions:**
1. Check `LocalStorageService().init()` called in main
2. Verify Hive box persists across restarts
3. On iOS, check app data not cleared by system
4. Try: `flutter clean` and rebuild
5. Check device storage isn't full

### Firebase & Backend Issues

#### Cloud Functions not executing
**Problem:** Functions deployed but not running
**Solutions:**
1. Check Cloud Functions logs in Firebase Console
2. Verify function is deployed: `firebase functions:list`
3. Check pubsub trigger schedule format
4. Ensure function has required permissions
5. Redeploy: `firebase deploy --only functions`

#### RevenueCat not validating subscription
**Problem:** Subscription shows as inactive
**Solutions:**
1. Verify subscription published in App Store/Play Store
2. Check test/sandbox user in RevenueCat
3. Ensure app store secrets configured in RevenueCat
4. Try on actual device (emulator subscriptions don't work)
5. Check RevenueCat subscription status in dashboard

#### Remote Config not updating
**Problem:** Old values persist after config change
**Solutions:**
1. Check `remoteConfig.fetchAndActivate()` is called
2. Minimum fetch interval is 12 hours - wait or reduce in dev
3. Verify config keys match in code
4. Check user cache: `await Purchases.invalidateCustomerInfoCache()`
5. Force refresh: clear app cache and restart

### Debugging Tips

#### Enable verbose logging
```dart
// In main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  logging: true,  // Enable debug logging
);
```

#### Check Hive contents
```dart
// In debug console
final box = Hive.box('lesson_progress');
print(box.values.toList());
```

#### Monitor Riverpod state changes
```dart
// In DevTools Console
ref.watch(lessonProgressProvider);
```

#### Test Firestore security rules
1. Go to Firebase Console
2. Firestore → Rules tab
3. Click "Rules Playground"
4. Simulate reads and writes without deploying

#### Profile performance
```bash
flutter run --profile
# Then open DevTools → Performance tab
```

## Common Error Messages

| Error | Cause | Fix |
|-------|-------|-----|
| `PlatformException(WrongContext...)` | Firebase context issue | Rebuild with credentials |
| `MissingPluginException` | Build not regenerated | `flutter clean && flutter pub get` |
| `E/Hive: Error reading Hive file` | Corrupted Hive db | Delete app data, reinstall |
| `java.lang.IllegalStateException: StreamListeners...` | Async operation after dispose | Use `.maybeWhen()` instead of `.when()` |
| `PERMISSION_DENIED: Missing or insufficient permissions` | Firestore rules blocking | Check rule simulator |
| `FirebaseCoreNotInitialized` | Firebase not initialized | Call `Firebase.initializeApp()` in main |

## Performance Checklist

- [ ] Questions loaded only once and cached
- [ ] Lessons lazy-loaded on demand
- [ ] Firestore queries include `.limit()`
- [ ] No rebuild loops in Riverpod providers
- [ ] Images cached via `cached_network_image`
- [ ] Timer only active during quiz
- [ ] Offline sync doesn't trigger on every state change
- [ ] Hive cache clear on logout

## Security Checklist

- [ ] No API keys in code
- [ ] Environment variables used for secrets
- [ ] Firestore rules restrict user access
- [ ] Anonymous users isolated in database
- [ ] RevenueCat webhook validates premium
- [ ] Storage rules require authentication
- [ ] Cloud Functions validate inputs
- [ ] No sensitive data in logs

## Getting Help

1. Check relevant documentation:
   - [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
   - [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

2. Check official docs:
   - [Flutter Docs](https://flutter.dev/docs)
   - [Firebase Docs](https://firebase.google.com/docs)
   - [Riverpod Docs](https://riverpod.dev)

3. Debug with:
   - Flutter DevTools: `flutter pub global run devtools`
   - Firebase Console logs
   - Android Studio Logcat / Xcode Console

4. Ask in communities:
   - Flutter Slack
   - Stack Overflow
   - r/FlutterDev

---

**Still stuck?** Make sure you've:
1. Read the error message carefully
2. Checked all prerequisites are installed
3. Verified credentials are correct
4. Cleaned and rebuilt: `flutter clean && flutter pub get`
5. Checked both device logs and Firebase Console logs
