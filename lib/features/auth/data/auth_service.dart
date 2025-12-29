import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if current user is Admin
  bool get isAdmin => currentUser?.email == 'admin@barber.com';

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use signInWithPopup (More robust for PWA/Web)
        return await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // Mobile: Use GoogleSignIn plugin (Native UX)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) return null; // User canceled the sign-in

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow; // Rethrow to show error in UI
    }
  }

  // Start Phone Cookie
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String message) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification (Android only mostly)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Falha na verificação de telefone');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout handling if needed
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Sign in with OTP
  Future<UserCredential?> signInWithOtp(
      String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with OTP: $e');
      rethrow;
    }
  }

  // Sign in Anonymously (For Testing/Guest)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out of Google: $e');
    }
    await _auth.signOut();
  }
}
