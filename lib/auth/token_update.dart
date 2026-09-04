import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yoked_in/auth/notification_service.dart';

Future<void> retryTokenUpdate(String userId) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Wait a bit for APNs token to be available
  await Future.delayed(const Duration(seconds: 5));

  try {
    final token = await NotificationService().getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({'token': token});
      print('Token updated successfully after retry');
    } else {
      // Try one more time after 10 seconds
      await Future.delayed(const Duration(seconds: 10));
      final retryToken = await NotificationService().getToken();
      if (retryToken != null) {
        await _firestore.collection('users').doc(userId).update({
          'token': retryToken,
        });
        print('Token updated successfully after second retry');
      }
    }
  } catch (e) {
    print('Error updating token after retry: $e');
    // Don't block login if token update fails
  }
}
