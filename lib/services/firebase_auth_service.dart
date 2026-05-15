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

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In is not supported on this platform.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw StateError('Google Sign-In did not return an ID token. '
          'Make sure GOOGLE_SERVER_CLIENT_ID is set to the Web client ID '
          'from your Firebase project.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (_googleInitialized) GoogleSignIn.instance.signOut(),
    ]);
    _googleInitialized = false;
  }
}