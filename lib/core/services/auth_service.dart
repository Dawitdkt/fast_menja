import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authState => _client.auth.onAuthStateChange;

  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => _client.auth.currentUser != null;

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  /// Create account with email and password
  Future<User?> createAccountWithEmail(
    String email,
    String password,
  ) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return response.user;
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Get access token for authenticated requests
  Future<String> getIdToken() async {
    final session = _client.auth.currentSession;
    return session?.accessToken ?? '';
  }
}
