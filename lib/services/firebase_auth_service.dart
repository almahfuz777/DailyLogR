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

  // ── Google Authentication ────────────────────────────────────────────────────────

  static Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    // Trigger the Google Sign-In flow
    final googleUser = await GoogleSignIn.instance.authenticate();

    // Obtain the auth details
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw StateError('Google Sign-In did not return an ID token. '
          'Make sure GOOGLE_SERVER_CLIENT_ID is set to the Web client ID '
          'from your Firebase project.');
    }

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    return await _auth.signInWithCredential(credential);
  }

  // ── Email/Password Authentication ────────────────────────────────────────────────

  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // ── Password Management ───────────────────────────────────────────────────

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> updatePassword(String newPassword, {String? oldPassword}) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (oldPassword != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!, 
          password: oldPassword,
        );
        await user.reauthenticateWithCredential(credential);
      }
      await user.updatePassword(newPassword);
    }
  }

  // ── Account Linking ───────────────────────────────────────────────────────

  static Future<void> linkGoogleAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('No user signed in');

    await _ensureGoogleInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    
    if (googleAuth.idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await user.linkWithCredential(credential);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (_googleInitialized) GoogleSignIn.instance.signOut(),
    ]);
  }
}