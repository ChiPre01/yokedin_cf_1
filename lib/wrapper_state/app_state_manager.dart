
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yoked_in/auth/notification_service.dart';

final appStateManagerProvider = ChangeNotifierProvider<AppStateManager>((ref) {
  return AppStateManager();
});

class AppStateManager extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  AppStateManager() {
    // Listen to app lifecycle changes (resume, pause, etc.)
    WidgetsBinding.instance.addObserver(this);
    // Initialize session when class is created
    initializeUserSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false); // Mark user offline on dispose
    super.dispose();
  }

  /// Handle app lifecycle to update online/offline
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnlineStatus(true); // mark online when resumed
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _setOnlineStatus(false); // mark offline otherwise
        break;
      default:
        break;
    }
  }

  /// Initialize user session (runs once per app start)
  Future<void> initializeUserSession() async {
    if (_isInitialized) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      // ADD THIS: Get FCM token
      final token = await NotificationService().getToken();
      final snapshot = await userDoc.get();
      // If user doc doesn't exist -> create new
      if (!snapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'photoURL': user.photoURL,
          'provider': _getProvider(user),
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          "token": token,
        });
      } else {
        // If exists -> just update online status + lastSeen
        await userDoc.update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing session: $e');
      _isInitialized = true; // prevent retry loop
    }
  }

  /// Set user online/offline
  Future<void> _setOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  /// Public method to manually set online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    await _setOnlineStatus(isOnline);
  }

  /// Detects which provider user used (Google or Email)
  String _getProvider(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'google';
      if (info.providerId == 'password') return 'email';
    }
    return 'email';
  }

  bool get isInitialized => _isInitialized;
}
