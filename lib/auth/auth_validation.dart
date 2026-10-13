import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthValidationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> validateCurrentUser() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    try {
      await currentUser.reload();

      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        return false;
      }

      // A valid Firebase Authentication account does not have to
      // already possess a Firestore profile document.
      //
      // Google sign-in may still be creating that document.
      final userDoc = await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      if (!userDoc.exists) {
        print(
          '[AUTH VALIDATION] Firestore profile is missing for '
          '${refreshedUser.uid}. Keeping the authenticated user signed in.',
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled') {
        await _auth.signOut();
        return false;
      }

      print('[AUTH VALIDATION] Firebase Auth error: ${e.code}');
      return false;
    } on FirebaseException catch (e) {
      // A Firestore/network error does not prove that the
      // Firebase Authentication account is invalid.
      print(
        '[AUTH VALIDATION] Firebase error: '
        '${e.code} - ${e.message}',
      );

      return true;
    } catch (e) {
      print('[AUTH VALIDATION] Unexpected error: $e');
      return true;
    }
  }

  Future<void> forceSignOut() async {
    await _auth.signOut();
  }
}
