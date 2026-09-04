class MessageRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderEmail;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final String? photoURL;
  MessageRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderEmail,
    required this.status,
    required this.createdAt,
    required this.photoURL,
  });

  factory MessageRequestModel.fromMap(Map<String, dynamic> map) {
    return MessageRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      status: map['status'] ?? 'pending',
      photoURL: map['photoURL'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'status': status,
      "photoURL": photoURL,
      'createdAt': createdAt,
    };
  }
}

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastSenderId: map['lastSenderId'] ?? '',
      lastMessageTime: map['lastMessageTime']?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    };
  }
}
