
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime? timestamp; // ✅ Nullable now
  final String type;
  final Map<String, DateTime>? readBy;
  final String? imageUrl; // Add this field for image
  final String? callType;
  final String? callStatus;
  final int? duration;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.timestamp, // ✅ allow null
    this.type = 'text',
    this.readBy,
    this.imageUrl,
    this.callType,
    this.callStatus,
    this.duration,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      // CHANGE THIS: Keep null timestamps as null, don't convert to DateTime.now()
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is Timestamp
                ? (map['timestamp'] as Timestamp).toDate()
                : map['timestamp'] is DateTime
                ? map['timestamp'] as DateTime
                : null) // Keep as null instead of DateTime.now()
          : null, // Keep as null
      readBy: Map<String, DateTime>.from(
        (map['readBy'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                key,
                value is Timestamp
                    ? value.toDate()
                    : value is DateTime
                    ? value
                    : DateTime.now(),
              ),
            ) ??
            {},
      ),
      type: map['type'] ?? 'user',
      imageUrl: map['imageUrl'],
      callType: map['callType'],
      callStatus: map['callStatus'],
      duration: map['duration'],
    );
  }

  /// Convert back to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      // ✅ if timestamp is null, use FieldValue.serverTimestamp()
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'type': type,
      'imageUrl': imageUrl,
      'readBy': readBy?.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      if (callType != null) 'callType': callType,
      if (callStatus != null) 'callStatus': callStatus,
      if (duration != null) 'duration': duration,
    };
  }
}
