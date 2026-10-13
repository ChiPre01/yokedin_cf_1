
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

      if (result != null && result.user != null) {
        state = state.copyWith(isLoading: false);

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainHomeScreen(),
            ),
          );
        }
      } else {
        debugPrint(
          '[GOOGLE AUTH PROVIDER] Sign-in returned no user or was canceled.',
        );

        state = state.copyWith(
          isLoading: false,
          error: 'Google Sign-In returned no authenticated user.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[GOOGLE AUTH PROVIDER] Sign-in failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
