
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:yoked_in/chat/message_model.dart';
import 'package:yoked_in/chat/model.dart';
import 'package:yoked_in/chat/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // -------------------- USERS --------------------
  Stream<List<UserModel>> getAllUsers() {
    if (currentUserId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .where((user) => user.uid != currentUserId)
              .toList(),
        );
  }

  Future<void> updateUserOnlineStatus(bool isOnline) async {
    if (currentUserId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // -------------------- MESSAGES --------------------
  Future<void> markMessagesAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();

      // IMPORTANT: Reset unread count FIRST
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'unreadCount.${currentUser.uid}': 0,
        // Add timestamp to force listeners to update
        'lastReadTime.${currentUser.uid}': FieldValue.serverTimestamp(),
      });

      // Then update individual messages
      final messagesQuery = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('readBy.${currentUser.uid}', isEqualTo: null)
          .get();

      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'readBy.${currentUser.uid}': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Clear all caches to ensure fresh data
      _chatsCache.clear();
      // _friendshipCache.clear();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<String> sendMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      final currentUser = _auth.currentUser!;
      final messageId = _firestore.collection('messages').doc().id;
      final batch = _firestore.batch();

      // Use server timestamp for consistency across devices
      batch.set(_firestore.collection('messages').doc(messageId), {
        'messageId': messageId,
        'senderId': currentUserId,
        'senderName': currentUser.displayName ?? 'User',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': {},
        'chatId': chatId,
        'type': 'user', // Add message type
      });

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        return 'Chat not found';
      }
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants']);
      final otherUserId = participants.firstWhere((id) => id != currentUserId);

      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        'unreadCount.$otherUserId': FieldValue.increment(1),
        'unreadCount.$currentUserId': 0,
      });

      await batch.commit();
      await _sendMessageNotification(
        chatId: chatId,
        message: message,
        otherUserId: otherUserId,
      );
      return 'success';
    } catch (e) {
      print('Error sending message: $e');
      return e.toString();
    }
  }

  // -------------------- SEND NOTIFICATION MESSAGE --------------------
  // ADD THIS NEW METHOD in ChatService:
  Future<void> _sendMessageNotification({
    required String chatId,
    required String message,
    required String otherUserId,
  }) async {
    try {
      final currentUser = _auth.currentUser!;
      final notificationId = _firestore.collection('users').doc().id;

      // Create notification document that triggers Cloud Function
      await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('notifications')
          .doc(notificationId)
          .set({
            'uid': currentUserId,
            'username': currentUser.displayName ?? 'User',
            'description': message,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'message',
            'chatId': chatId,
          });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // -------------------- MESSAGE REQUESTS --------------------
  // Future<String> sendMessageRequest({
  //   required String receiverId,
  //   required String receiverName,
  //   required String receiverEmail,
  // }) async {
  //   try {
  //     final currentUser = _auth.currentUser!;
  //     final requestId = '${currentUserId}_$receiverId';
  //     // get phot url from firestore user collection
  //     final userDoc = await _firestore
  //         .collection("users")
  //         .doc(currentUserId)
  //         .get();
  //     String? userPhotoURL;
  //     if (userDoc.exists) {
  //       final userModel = UserModel.fromMap(userDoc.data()!);
  //       userPhotoURL = userModel.photoURL;
  //     }
  //     final existingRequest = await _firestore
  //         .collection('messageRequests')
  //         .doc(requestId)
  //         .get();
  //     if (existingRequest.exists &&
  //         existingRequest.data()?['status'] == 'pending') {
  //       return 'Request already sent';
  //     }
  //     final request = MessageRequestModel(
  //       id: requestId,
  //       senderId: currentUserId,
  //       receiverId: receiverId,
  //       photoURL: userPhotoURL,
  //       senderName: currentUser.displayName ?? 'User',
  //       senderEmail: currentUser.email ?? '',
  //       status: 'pending',
  //       createdAt: DateTime.now(),
  //     );

  //     await _firestore
  //         .collection('messageRequests')
  //         .doc(requestId)
  //         .set(request.toMap());
  //     return 'success';
  //   } catch (e) {
  //     return e.toString();
  //   }
  // }
  Future<String> sendMessageRequest({
    required String receiverId,
    required String receiverName,
    required String receiverEmail,
  }) async {
    try {
      final currentUser = _auth.currentUser!;
      final requestId = '${currentUserId}_$receiverId';

      // Get sender's photo URL
      final userDoc = await _firestore
          .collection("users")
          .doc(currentUserId)
          .get();
      String? userPhotoURL;
      if (userDoc.exists) {
        final userModel = UserModel.fromMap(userDoc.data()!);
        userPhotoURL = userModel.photoURL;
      }

      final existingRequest = await _firestore
          .collection('messageRequests')
          .doc(requestId)
          .get();

      if (existingRequest.exists &&
          existingRequest.data()?['status'] == 'pending') {
        return 'Request already sent';
      }

      final request = MessageRequestModel(
        id: requestId,
        senderId: currentUserId,
        receiverId: receiverId,
        photoURL: userPhotoURL,
        senderName: currentUser.displayName ?? 'User',
        senderEmail: currentUser.email ?? '',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('messageRequests')
          .doc(requestId)
          .set(request.toMap());

      // ✅ ADD THIS: Send friend request notification
      await _sendFriendRequestNotification(
        receiverId: receiverId,
        senderName: currentUser.displayName ?? 'User',
        senderPhotoURL: userPhotoURL,
      );

      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ ADD THIS NEW METHOD in ChatService:
  Future<void> _sendFriendRequestNotification({
    required String receiverId,
    required String senderName,
    String? senderPhotoURL,
  }) async {
    try {
      final notificationId = _firestore.collection('users').doc().id;

      // Create notification document that triggers Cloud Function
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .doc(notificationId)
          .set({
            'uid': currentUserId,
            'username': senderName,
            'description': '$senderName sent you a friend request',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'friend_request',
            'senderPhotoURL': senderPhotoURL,
            'read': false,
          });

      print('Friend request notification sent to $receiverId');
    } catch (e) {
      print('Error sending friend request notification: $e');
      // Don't throw - allow friend request to succeed even if notification fails
    }
  }

  Stream<List<MessageRequestModel>> getPendingRequests() {
    if (currentUserId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('messageRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<String> acceptMessageRequest(String requestId, String senderId) async {
    try {
      final batch = _firestore.batch();

      // Update request status
      batch.update(_firestore.collection('messageRequests').doc(requestId), {
        'status': 'accepted',
      });

      // Create friendship
      final friendshipId = _generateChatId(currentUserId, senderId);
      batch.set(_firestore.collection('friendships').doc(friendshipId), {
        'participants': [currentUserId, senderId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create chat
      batch.set(_firestore.collection('chats').doc(friendshipId), {
        'chatId': friendshipId,
        'participants': [currentUserId, senderId],
        'lastMessage': '',
        'lastSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, senderId: 0},
      });

      // System message
      final messageId = _firestore.collection('messages').doc().id;
      batch.set(_firestore.collection('messages').doc(messageId), {
        'messageId': messageId,
        'chatId': friendshipId,
        'senderId': 'system',
        'senderName': 'System',
        'message': 'Request has been accepted. You can now start chatting!',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      await batch.commit();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> rejectMessageRequest(
    String requestId, {
    bool deleteRequest = true,
  }) async {
    try {
      if (deleteRequest) {
        await _firestore.collection('messageRequests').doc(requestId).delete();
      } else {
        await _firestore.collection('messageRequests').doc(requestId).update({
          'status': 'rejected',
        });
      }
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // -------------------- CHATS --------------------
  // Add caching for chats
  final Map<String, List<ChatModel>> _chatsCache = {};
  // DateTime? _lastChatsFetch;

  Stream<List<ChatModel>> getUserChats() {
    if (currentUserId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .limit(10) // Limit initial chat load
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .toList();
          return docs;
        });
  }

  Stream<List<MessageModel>> getChatMessages(
    String chatId, {
    int limit = 20, // Reduce from 50 to 20
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map(
            (doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
      print("sizeofdocs2 ${docs.length}");
      return docs;
    });
  }

  // Unfriend user
  Future<String> unfriendUser(String chatId, String friendId) async {
    try {
      final batch = _firestore.batch();

      // Delete friendship
      batch.delete(_firestore.collection('friendships').doc(chatId));

      // Delete chat
      batch.delete(_firestore.collection('chats').doc(chatId));

      // Delete all messages in the chat
      final messages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .get();

      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // Check if users are friends
  Future<bool> areUsersFriends(String userId1, String userId2) async {
    final chatId = _generateChatId(userId1, userId2);
    // Only read from Firestore if not cached
    final friendship = await _firestore
        .collection('friendships')
        .doc(chatId)
        .get();

    final exists = friendship.exists;
    return exists;
  }

  // -------------------- UTILS --------------------
  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    if (currentUserId.isEmpty) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typing.$currentUserId': isTyping,
        'typingTimestamp.$currentUserId': FieldValue.serverTimestamp(),
      });

      // Only set cleanup timer when stopping typing (for safety)
      if (!isTyping) {
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await _firestore.collection('chats').doc(chatId).update({
              'typing.$currentUserId': false,
            });
          } catch (e) {
            // Ignore errors for cleanup
          }
        });
      }
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // -------------------- TYPING_STATUS --------------------
  // AFTER: Debounced updates with auto-cleanup
  Stream<Map<String, bool>> getTypingStatus(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return <String, bool>{};

      final data = doc.data() as Map<String, dynamic>;
      final typing = data['typing'] as Map<String, dynamic>? ?? {};
      final typingTimestamp =
          data['typingTimestamp'] as Map<String, dynamic>? ?? {};

      final result = <String, bool>{};
      final now = DateTime.now();

      typing.forEach((userId, isTyping) {
        if (userId != currentUserId) {
          // Check if typing status is recent (within 5 seconds)
          final timestamp = typingTimestamp[userId];
          if (timestamp != null && isTyping == true) {
            final typingTime = (timestamp as Timestamp).toDate();
            final isRecent = now.difference(typingTime).inSeconds < 5;
            result[userId] = isRecent;
          } else {
            result[userId] = false;
          }
        }
      });
      print("sizeofdocs3 ${result.length}");

      return result;
    });
  }

  // -------------------- IMAGE MESSAGES --------------------
  Future<String> uploadImage(File imageFile, String chatId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${currentUserId}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatId)
          .child(fileName);

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("sizeofdocs4 ${downloadUrl.length}");
      print("sizeofdocs5 ${uploadTask}");
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  Future<String> sendImageMessage({
    required String chatId,
    required String imageUrl,
    String? caption,
  }) async {
    try {
      final currentUser = _auth.currentUser!;
      final messageId = _firestore.collection('messages').doc().id;

      final batch = _firestore.batch();

      // Create image message
      batch.set(_firestore.collection('messages').doc(messageId), {
        'messageId': messageId,
        'senderId': currentUserId,
        'senderName': currentUser.displayName ?? 'User',
        'message': caption ?? '', // Caption text
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': {},
        'chatId': chatId,
        'type': 'image',
      });

      // Update chat with last message
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        return 'Chat not found';
      }

      final chatData = chatDoc.data()!;
      // print("sizeofdocs6 ${chatData.length}");
      final participants = List<String>.from(chatData['participants']);
      final otherUserId = participants.firstWhere((id) => id != currentUserId);

      batch.update(_firestore.collection('chats').doc(chatId), {
        // 'lastMessage': caption?.isNotEmpty == true ? caption : '📷 Photo',
        'lastMessage': (caption != null && caption.trim().isNotEmpty)
            ? caption
            : '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        'unreadCount.$otherUserId': FieldValue.increment(1),
        'unreadCount.$currentUserId': 0,
      });
      // print("sizeofdocs7 ${batch}");
      await batch.commit();
      // For notification
      await _sendMessageNotification(
        chatId: chatId,
        message: caption?.trim().isNotEmpty == true ? caption! : '📷 Photo',
        otherUserId: otherUserId,
      );
      return 'success';
    } catch (e) {
      print('Error sending image message: $e');
      return e.toString();
    }
  }

  Future<String> sendImageWithUpload({
    required String chatId,
    required File imageFile,
    String? caption,
  }) async {
    // Upload image first
    final imageUrl = await uploadImage(imageFile, chatId);
    if (imageUrl.isEmpty) {
      return 'Failed to upload image';
    }

    // Send image message
    return await sendImageMessage(
      chatId: chatId,
      imageUrl: imageUrl,
      caption: caption,
    );
  }

  // -------------------- CALL HISTORY --------------------
  // Add this single method to your existing ChatService class
  Future<String> addCallHistory({
    required String chatId,
    required bool isVideoCall,
    required String callStatus, // 'answered', 'missed'
    int? duration,
  }) async {
    try {
      final currentUser = _auth.currentUser!;
      final messageId = _firestore.collection('messages').doc().id;

      await _firestore.collection('messages').doc(messageId).set({
        'messageId': messageId,
        'senderId': currentUserId,
        'senderName': currentUser.displayName ?? 'User',
        'message': isVideoCall ? 'Video call' : 'Audio call',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': {},
        'chatId': chatId,
        'type': 'call',
        'callType': isVideoCall ? 'video' : 'audio',
        'callStatus': callStatus,
      });
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }
}
