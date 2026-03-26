import 'package:supabase_flutter/supabase_flutter.dart';

class AppAuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const AppAuthUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.isAnonymous,
  });

  factory AppAuthUser.fromSupabase(User user) {
    final provider = user.appMetadata['provider'] as String?;
    final isAnonymous = provider == 'anonymous';

    return AppAuthUser(
      uid: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      isAnonymous: isAnonymous,
    );
  }
}

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  Stream<AppAuthUser?> get authStateChanges async* {
    yield currentUser;
    yield* _auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return AppAuthUser.fromSupabase(user);
    });
  }

  AppAuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppAuthUser.fromSupabase(user);
  }

  bool get isSignedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> createAccountWithEmail(String email, String password) {
    return _auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithGoogle() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  Future<void> signInWithApple() {
    return _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  Future<AuthResponse> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) {
    return _auth.updateUser(
      UserAttributes(
        data: {
          if (displayName != null) 'display_name': displayName,
          if (photoURL != null) 'avatar_url': photoURL,
        },
      ),
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  Future<String> getIdToken() async {
    return _auth.currentSession?.accessToken ?? '';
  }
}
