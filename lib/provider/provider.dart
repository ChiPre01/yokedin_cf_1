// Add this provider
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/auth/auth_validation.dart';

final authValidationServiceProvider = Provider<AuthValidationService>((ref) {
  return AuthValidationService();
});

// Update your existing authStateProvider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authValidationServiceProvider);

  return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
    if (user != null) {
      // Validate user when auth state changes
      final isValid = await authService.validateCurrentUser();
      if (!isValid) {
        return null; // Return null to trigger login screen
      }
    }
    return user;
  });
});