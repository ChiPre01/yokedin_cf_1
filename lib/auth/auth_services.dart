import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/auth/display_name_service.dart';
import 'package:yoked_in/auth/notification_service.dart';
import 'package:yoked_in/auth/retry_token_update.dart';

class AuthMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DisplayNameService _displayNameService = DisplayNameService();

Future<String> signUpUser({
  required String email,
  required String password,
  required String name,
}) async {
  User? createdUser;

  try {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty ||
        password.isEmpty ||
        trimmedName.isEmpty) {
      return 'Please enter all fields';
    }

    // Create the Firebase Authentication account first.
    // Firestore rules can now recognize this authenticated user.
    final credential = await _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );

    createdUser = credential.user;

    if (createdUser == null) {
      return 'Account creation failed. Please try again.';
    }

    // Check for duplicate names after authentication.
    final nameTaken = await _displayNameService.isNameTaken(
      trimmedName,
      excludeUid: createdUser.uid,
    );

    if (nameTaken) {
      // Remove the newly created account because the name is unavailable.
      await createdUser.delete();
      createdUser = null;

      return 'This name is already taken. Please choose a different name.';
    }

    await createdUser.updateDisplayName(trimmedName);

    String? token;

    // Notification token failure should not block account creation.
    try {
      token = await NotificationService().getToken();
    } catch (e) {
      print('[SIGNUP] Could not retrieve notification token: $e');
    }

    // Create the profile in the existing users collection.
    await _firestore.collection('users').doc(createdUser.uid).set({
      'uid': createdUser.uid,
      ..._displayNameService.nameFields(trimmedName),
      'email': trimmedEmail,
      'photoURL': null,
      'isOnline': false,
      'provider': 'email',
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'token': token,
    });

    // Update the token separately; token failures should not block signup.
    try {
      await NotificationService().updateUserToken(createdUser.uid);
    } catch (e) {
      print('[SIGNUP] Notification token update failed: $e');
    }

    if (token == null) {
      retryTokenUpdate(createdUser.uid);
    }

    return 'success';
  } on FirebaseAuthException catch (e) {
    return e.message ?? 'Unable to create your account.';
  } on FirebaseException catch (e) {
    print('[SIGNUP] Firebase error: ${e.code} - ${e.message}');

    // If profile creation fails, avoid leaving an orphaned Auth account.
    if (createdUser != null) {
      try {
        await createdUser.delete();
      } catch (cleanupError) {
        print('[SIGNUP] Account cleanup failed: $cleanupError');
      }
    }

    return 'Unable to create your account: ${e.message ?? e.code}';
  } catch (e) {
    print('[SIGNUP] Unexpected error: $e');
    return 'Unable to create your account: $e';
  }
}

  // Login with online status update
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Please enter all fields";
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Update online status after login
      if (_auth.currentUser != null) {
        await NotificationService().updateUserToken(_auth.currentUser!.uid);
      }
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  //Logout with online status update
  Future<void> signOut() async {
    if (_auth.currentUser != null) {
      // Set offline before signing out
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
  }
}

final authMethodProvider = Provider<AuthMethod>((ref) {
  return AuthMethod();
});
