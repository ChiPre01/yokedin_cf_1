
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String? groupPhotoURL;
  final String? callInitiatorId;
  final List<String> members; // All member UIDs
  final List<String> admins; // Admin UIDs
  final String createdBy;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final bool anyoneCanEditInfo; // Toggle for group info editing
  final Map<String, int> unreadCount;

  GroupModel({
    required this.groupId,
    required this.groupName,
    this.callInitiatorId,
    this.groupPhotoURL,
    required this.members,
    required this.admins,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageTime,
    this.anyoneCanEditInfo = false,
    this.unreadCount = const {},
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map['groupId'] ?? '',
      callInitiatorId: map['callInitiatorId'] ?? '',
      groupName: map['groupName'] ?? '',
      groupPhotoURL: map['groupPhotoURL'],
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime']?.toDate(),
      anyoneCanEditInfo: map['anyoneCanEditInfo'] ?? false,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoURL': groupPhotoURL,
      'members': members,
      'admins': admins,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'callInitiatorId': callInitiatorId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'anyoneCanEditInfo': anyoneCanEditInfo,
      'unreadCount': unreadCount,
    };
  }

  bool isAdmin(String userId) => admins.contains(userId);
  bool isMember(String userId) => members.contains(userId);

  // ✅ Add helper method to get unread count for a user
  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;
}

class GroupMessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime? timestamp;
  final String type; // 'text', 'image', 'system'
  final String? imageUrl;
  final String? senderPhotoURL;

  GroupMessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.timestamp,
    this.type = 'text',
    this.imageUrl,
    this.senderPhotoURL,
  });

  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp more gracefully
    DateTime? timestamp;
    if (map['timestamp'] != null) {
      if (map['timestamp'] is Timestamp) {
        timestamp = (map['timestamp'] as Timestamp).toDate();
      } else if (map['timestamp'] is DateTime) {
        timestamp = map['timestamp'] as DateTime;
      }
    }
    return GroupMessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      timestamp: timestamp ?? DateTime.now(),
      type: map['type'] ?? 'text',
      imageUrl: map['imageUrl'],
      senderPhotoURL: map['senderPhotoURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'type': type,
      'imageUrl': imageUrl,
      'senderPhotoURL': senderPhotoURL,
    };
  }
}
