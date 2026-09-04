
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/other_screens/main_home.dart';

class AuthenticatedWrapper extends ConsumerStatefulWidget {
  const AuthenticatedWrapper({super.key});

  @override
  ConsumerState<AuthenticatedWrapper> createState() =>
      _AuthenticatedWrapperState();
}

// class _AuthenticatedWrapperState extends ConsumerState<AuthenticatedWrapper> {
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeSession();
//   }

//   Future<void> _initializeSession() async {
//     try {
//       final appManager = ref.read(appStateManagerProvider);

//       // Run session initialization with timeout (max 10s)
//       await Future.any([
//         appManager.initializeUserSession(),
//         Future.delayed(
//           const Duration(seconds: 10),
//           () => throw TimeoutException('Session init timed out'),
//         ),
//       ]);

//       if (mounted) {
//         setState(() {
//           _isInitialized = true; // move to home screen after init
//         });
//       }
//     } catch (e) {
//       print('Error initializing session: $e');
//       if (mounted) {
//         // Still allow moving forward even if init fails
//         setState(() {
//           _isInitialized = true; // prevent infinite loading
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized) {
//       // Show loader until user session is initialized
//       return const Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Setting up your account...'),
//             ],
//           ),
//         ),
//       );
//     }
//     // Once initialized -> go to main app home screen
//     return const MainHomeScreen();
//   }
// }

class _AuthenticatedWrapperState extends ConsumerState<AuthenticatedWrapper> {
  @override
  // void initState() {
  //   super.initState();
  //   // Don't await - run in background
  //   _initializeSessionInBackground();
  // }
  // Future<void> _initializeSessionInBackground() async {
  //   try {
  //     final appManager = ref.read(appStateManagerProvider);
  //     // Run without blocking UI
  //     unawaited(
  //       appManager.initializeUserSession().timeout(
  //         const Duration(seconds: 5),
  //         onTimeout: () => print('Background init timed out'),
  //       ),
  //     );
  //   } catch (e) {
  //     print('Error in background initialization: $e');
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    // Go directly to home screen
    // Initialization happens in background
    return const MainHomeScreen();
  }
}
