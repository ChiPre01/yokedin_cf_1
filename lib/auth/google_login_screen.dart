
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/auth/google_auth_provider.dart';
import 'package:yoked_in/widgets/utilis.dart';

class GoogleLoginScreen extends ConsumerWidget {
  const GoogleLoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(googleAuthProvider);
    final authNotifier = ref.read(googleAuthProvider.notifier);

    // Show error snackbar if error exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.error != null) {
        // print("Error:${authState.error!} ");
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: "Unable to login",
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          ref.read(googleAuthProvider.notifier).clearError();
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
                              "images/yokedinGL.png",
                              height: 35,
                              fit: BoxFit.cover,
                            ),
                SizedBox(width: 15),
                Text(
                  authState.isLoading
                      ? "Signing In..."
                      : "Continue with Google",
                  style: TextStyle(
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
        if (authState.isLoading) CircularProgressIndicator(color: Colors.black),
      ],
    );
  }
}
