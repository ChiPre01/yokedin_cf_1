
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/auth/google_auth_provider.dart';
import 'package:yoked_in/widgets/utilis.dart';

class GoogleLoginScreen extends ConsumerWidget {
  const GoogleLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(googleAuthProvider);
    final authNotifier = ref.read(googleAuthProvider.notifier);

    ref.listen(googleAuthProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        debugPrint('[GOOGLE LOGIN SCREEN] Actual error: ${next.error}');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          showAppSnackbar(
            context: context,
            type: SnackbarType.error,
            description: next.error!,
          );
        });
      }
    });

    return Column(
      children: [
        MaterialButton(
          elevation: 0,
          color: Colors.lightBlueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onPressed: authState.isLoading
              ? null
              : () {
                  authNotifier.clearError();
                  authNotifier.signInWithGoogle(context);
                },
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/yokedinGL.png',
                  height: 35,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 15),
                Text(
                  authState.isLoading
                      ? 'Signing In...'
                      : 'Continue with Google',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (authState.isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.black),
          ),
      ],
    );
  }
}
