import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoked_in/chat/user_profile_model.dart';
import 'package:yoked_in/services/cloudflare_media_service.dart';

/// Manages the signed-in user's profile data and profile photo.
class ProfileNotifier extends StateNotifier<ProfileState> {
  late final StreamSubscription<User?> _authSubscription;

  ProfileNotifier() : super(ProfileState(isLoading: true)) {
    _listenToAuthChanges();
  }

  /// Listen for Firebase Authentication changes.
  void _listenToAuthChanges() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        if (state.userId != user.uid) {
          loadUserData(user);
        }
      } else {
        state = ProfileState(isLoading: false);
      }
    });
  }

  /// Load the signed-in user's profile from Firestore.
  Future<void> loadUserData([User? user]) async {
    final currentUser = user ?? FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      state = ProfileState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? <String, dynamic>{};

        state = ProfileState(
          photoUrl: data['photoURL'] as String?,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? currentUser.email ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          userId: currentUser.uid,
          isLoading: false,
        );
      } else {
        state = ProfileState(
          userId: currentUser.uid,
          isLoading: false,
        );
      }
    } catch (e) {
      state = ProfileState(
        userId: currentUser.uid,
        isLoading: false,
      );
    }
  }

  /// Refresh the current user's profile.
  void refresh() {
    loadUserData();
  }

  /// Pick a profile photo and upload it to Cloudflare R2.
  ///
  /// The resulting media URL is saved in the existing Firestore
  /// users/{uid}.photoURL field to preserve the current data structure.
  Future<bool> updateProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final picker = ImagePicker();

    final XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
    } catch (e) {
      return false;
    }

    if (pickedFile == null) {
      return false;
    }

    state = state.copyWith(isUploading: true);

    try {
      // Upload the image to Cloudflare R2 through the Worker.
      final uploadResult =
          await CloudflareMediaService.instance.uploadFile(pickedFile);

      final newUrl = uploadResult['url'] as String;

      // Preserve the existing Firestore profile field.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'photoURL': newUrl,
      });

      // Update the local profile state.
      state = state.copyWith(
        photoUrl: newUrl,
        isUploading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false);
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

/// Riverpod provider for the user's profile.
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
