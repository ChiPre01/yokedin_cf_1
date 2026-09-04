
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoked_in/chat/user_profile.dart';

/// Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  late final StreamSubscription<User?> _authSubscription;

  ProfileNotifier() : super(ProfileState(isLoading: true)) {
    _listenToAuthChanges();
  }

  /// Listen to Firebase Auth state changes
  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User logged in - load their data
        if (state.userId != user.uid) {
          // Only reload if it's a different user
          loadUserData(user);
        }
      } else {
        // User logged out - clear state
        state = ProfileState(isLoading: false);
      }
    });
  }

  /// Load user data from Firestore
  Future<void> loadUserData([User? user]) async {
    final currentUser = user ?? FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      state = ProfileState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        state = ProfileState(
          photoUrl: doc["photoURL"],
          name: doc["name"],
          email: doc["email"],
          createdAt: (doc["createdAt"] as Timestamp?)?.toDate(),
          userId: currentUser.uid,
          isLoading: false,
        );
      } else {
        state = ProfileState(userId: currentUser.uid, isLoading: false);
      }
    } catch (e) {
      state = ProfileState(userId: currentUser.uid, isLoading: false);
    }
  }

  /// Force refresh user data - This method was missing!
  void refresh() {
    loadUserData();
  }

  /// Pick & upload new profile image
  Future<bool> updateProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return false;

    state = state.copyWith(isUploading: true);

    File file = File(pickedFile.path);

    try {
      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("profile_pictures")
          .child("${user.uid}.jpg");

      await storageRef.putFile(file);
      final newUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"photoURL": newUrl},
      );

      // Update state
      state = state.copyWith(photoUrl: newUrl, isUploading: false);

      return true; // success
    } catch (e) {
      state = state.copyWith(isUploading: false);
      return false; // failed
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

/// Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});
