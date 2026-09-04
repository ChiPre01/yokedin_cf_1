
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yoked_in/chat/message_model.dart';

/// Builds the "message status" icon (✓, ✓✓, online check)
/// depending on:
/// - who sent the message
/// - whether the receiver is online
/// - whether the message was read
Widget buildMessageStatusIcon(MessageModel message, uid) {
  // Get the current logged-in user id
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  // Only show status for messages sent BY current user
  if (message.senderId != currentUserId) {
    return const SizedBox();
  }
  // Listen to the receiver's (chat partner's) user document
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
    builder: (context, userSnapshot) {
      bool isReceiverOnline = false;
      // Check if user document exists and fetch "isOnline" field
      if (userSnapshot.hasData && userSnapshot.data!.exists) {
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        isReceiverOnline = userData['isOnline'] ?? false;
      }
      // ✅ Check if the RECEIVER has read this message
      final isMessageRead = message.readBy?.containsKey(uid) ?? false;

      if (isMessageRead) {
        // Message was read by receiver → show ✓✓ (white)
        return const Icon(Icons.done_all, size: 16, color: Colors.white);
      } else if (isReceiverOnline) {
        // Receiver is online but hasn’t read → show ✓✓ (grey)
        return const Icon(Icons.done_all, size: 16, color: Colors.black54);
      } else {
        // Message delivered but receiver offline → show single ✓
        return const Icon(Icons.check, size: 16, color: Colors.black54);
      }
    },
  );
}
