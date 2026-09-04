import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yoked_in/auth/google_auth.dart';
import 'package:yoked_in/auth/google_auth_service.dart';
import 'package:yoked_in/other_screens/main_home.dart';

class GoogleAuthNotifier extends StateNotifier<GoogleAuthState> {
  final FirebaseServices _firebaseServices;

  GoogleAuthNotifier(this._firebaseServices) : super(GoogleAuthState());

  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _firebaseServices.signInWithGoogle();
      state = state.copyWith(isLoading: false);

      if (result != null && result.user != null) {
        // Small delay to let auth state sync
        await Future.delayed(const Duration(milliseconds: 300));

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainHomeScreen()),
          );
        }
      } else {
        state = state.copyWith(error: 'Google Sign-In canceled');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google Sign-In failed: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final googleAuthProvider =
    StateNotifierProvider<GoogleAuthNotifier, GoogleAuthState>((ref) {
      final firebaseService = ref.read(firebaseServicesProvider);
      return GoogleAuthNotifier(firebaseService);
    });
