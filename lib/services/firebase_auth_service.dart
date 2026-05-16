// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication.
/// [Firebase.initializeApp()] has already been called in `main()`.
class FirebaseAuthService {
  FirebaseAuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool _googleInitialized = false;

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;

    final serverClientId = _serverClientId.isEmpty ? null : _serverClientId;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _googleInitialized = true;
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Google Sign-In ────────────────────────────────────────────────────────

  static Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    // 1. Trigger the Google Sign-In flow (v7 syntax uses authenticate)
    final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

    if (googleUser == null) {
      throw StateError('Sign-in aborted by user.');
    }

    // 2. Obtain the auth details (v7 no longer includes accessToken here)
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw StateError('Google Sign-In did not return an ID token. '
          'Make sure GOOGLE_SERVER_CLIENT_ID is set to the Web client ID '
          'from your Firebase project.');
    }

    // 3. Create a new credential (Firebase only needs the idToken)
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase with the Google credential
    return await _auth.signInWithCredential(credential);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (_googleInitialized) GoogleSignIn.instance.signOut(),
    ]);
  }
}