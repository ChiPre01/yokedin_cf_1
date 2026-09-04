
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthValidationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validate if current user still exists in Firestore
  Future<bool> validateCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;

      // If no user is logged in, return false
      if (currentUser == null) {
        return false;
      }

      // Reload user data to check if account still exists in Firebase Auth
      await currentUser.reload();

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // If user doesn't exist in Firestore, sign out
      if (!userDoc.exists) {
        await _auth.signOut();
        return false;
      }

      return true;
    } on FirebaseAuthException catch (e) {
      // If user is deleted from Firebase Auth, sign out
      if (e.code == 'user-not-found' || e.code == 'user-disabled') {
        await _auth.signOut();
        return false;
      }
      return false;
    } catch (e) {
      print('Error validating user: $e');
      return false;
    }
  }

  // Force sign out
  Future<void> forceSignOut() async {
    await _auth.signOut();
  }
}
