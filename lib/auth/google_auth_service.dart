import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yoked_in/auth/display_name_service.dart';
import 'package:yoked_in/auth/notification_service.dart';

final firebaseServicesProvider = Provider<FirebaseServices>((ref) {
  return FirebaseServices();
});

class FirebaseServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static final DisplayNameService _displayNameService =
      DisplayNameService();

  // Keep one initialization Future so Google Sign-In is initialized once.
  static Future<void>? _initialization;

  static Future<void> initSignIn() {
    return _initialization ??= _googleSignIn.initialize(
      serverClientId:
          '433406558921-glo29so9hvdpoudod3717qgmjiujdndp.apps.googleusercontent.com',
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('[GOOGLE AUTH] Starting Google Sign-In...');

      final UserCredential userCredential;

      if (kIsWeb) {
        // Web: authenticate using Firebase's Google popup.
        debugPrint('[GOOGLE AUTH] Using Firebase Google popup on web...');

        userCredential = await _auth.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        // Android and other supported native platforms.
        debugPrint('[GOOGLE AUTH] Initializing native Google Sign-In...');

        await initSignIn();

        debugPrint('[GOOGLE AUTH] Opening Google account selector...');

        final GoogleSignInAccount googleUser =
            await _googleSignIn.authenticate();

        debugPrint('[GOOGLE AUTH] Google account selected.');
        debugPrint('[GOOGLE AUTH] Email: ${googleUser.email}');

        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        final String? idToken = googleAuth.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw FirebaseAuthException(
            code: 'google-id-token-missing',
            message:
                'Google Sign-In did not return an ID token. Check your OAuth client configuration.',
          );
        }

        debugPrint('[GOOGLE AUTH] Google ID token received.');

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        debugPrint('[GOOGLE AUTH] Signing in to Firebase...');

        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-user-null',
          message: 'Firebase completed sign-in without returning a user.',
        );
      }

      debugPrint(
        '[GOOGLE AUTH] Firebase sign-in successful. UID: ${user.uid}',
      );

      final DocumentReference<Map<String, dynamic>> userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Check whether this Google account already has a Firestore profile.
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await userDoc.get();

      // Get Google's display name, using "User" if it is empty.
      final String googleName = (user.displayName ?? '').trim().isEmpty
          ? 'User'
          : user.displayName!.trim();

      String finalName;

      if (docSnapshot.exists) {
        // Returning users keep their existing Firestore display name.
        final existingName = docSnapshot.data()?['name'];

        if (existingName is String && existingName.trim().isNotEmpty) {
          finalName = existingName.trim();

          debugPrint(
            '[GOOGLE AUTH] Existing profile found. '
            'Keeping saved name: $finalName',
          );
        } else {
          // Repair a profile whose name is missing or empty.
          finalName = await _displayNameService.generateAvailableName(
            googleName,
          );

          debugPrint(
            '[GOOGLE AUTH] Generated name for incomplete profile: $finalName',
          );
        }
      } else {
        // New Google users get the original name if available,
        // or the first available numeric suffix if it is already taken.
        finalName = await _displayNameService.generateAvailableName(
          googleName,
        );

        debugPrint('[GOOGLE AUTH] Available display name: $finalName');
      }

      // Keep Firebase Authentication's display name consistent with
      // the name stored in Firestore.
      if (user.displayName != finalName) {
        await user.updateDisplayName(finalName);
      }

      String? token;

      // Notifications must not prevent authentication from succeeding.
      try {
        token = await NotificationService().getToken();
      } catch (e) {
        debugPrint('[GOOGLE AUTH] Could not retrieve FCM token: $e');
      }

      // Save the profile in the existing users collection.
      // Merge preserves other fields already used by your application.
      await userDoc.set({
        'uid': user.uid,
        ..._displayNameService.nameFields(finalName),
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'provider': 'google',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        if (!docSnapshot.exists)
          'createdAt': FieldValue.serverTimestamp(),
        'token': token,
      }, SetOptions(merge: true));

      debugPrint(
        '[GOOGLE AUTH] Firestore profile saved successfully. '
        'Name: $finalName',
      );

      // Update the notification token if possible.
      try {
        await NotificationService().updateUserToken(user.uid);
      } catch (e) {
        debugPrint('[GOOGLE AUTH] FCM token update skipped: $e');
      }

      debugPrint('[GOOGLE AUTH] Google Sign-In completed successfully.');

      return userCredential;
    } on GoogleSignInException catch (e, stackTrace) {
      debugPrint('[GOOGLE AUTH] GoogleSignInException');
      debugPrint('[GOOGLE AUTH] Code: ${e.code}');
      debugPrint('[GOOGLE AUTH] Description: ${e.description}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('[GOOGLE AUTH] FirebaseAuthException');
      debugPrint('[GOOGLE AUTH] Code: ${e.code}');
      debugPrint('[GOOGLE AUTH] Message: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('[GOOGLE AUTH] Firestore/Firebase exception');
      debugPrint('[GOOGLE AUTH] Code: ${e.code}');
      debugPrint('[GOOGLE AUTH] Message: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[GOOGLE AUTH] Unexpected exception: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final User? user = _auth.currentUser;

      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'isOnline': false,
                'lastSeen': FieldValue.serverTimestamp(),
              });
        } catch (e) {
          debugPrint(
            '[GOOGLE AUTH] Could not update offline status: $e',
          );
        }
      }

      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut();

      debugPrint('[GOOGLE AUTH] Sign-out completed.');
    } catch (e, stackTrace) {
      debugPrint('[GOOGLE AUTH] Sign-out failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
