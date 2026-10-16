import 'package:flutter/material.dart';
import 'package:yoked_in/group_chat/group_chat_model.dart';
import 'package:yoked_in/helper/current_time.dart';
import 'package:yoked_in/widgets/user_avatar.dart';

class ChatMessage extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;

  const ChatMessage({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final hasImage = message.imageUrl != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              UserAvatar(
                photoUrl: message.senderPhotoURL,
                radius: 16,
                fallbackIcon: Icons.person,
              ),
            if (!isMe) const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: EdgeInsets.all(hasImage ? 4 : 12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.green[50] : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.network(
                              message.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white,
                                    spreadRadius: 5,
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: currentTime(message.timestamp),
                            ),
                          ),
                        ],
                      ),
                    if (message.message.isNotEmpty)
                      if (!isMe)
                        Text(
                          message.message,
                          style: const TextStyle(color: Colors.black),
                        ),
                    if (isMe && !hasImage)
                      Wrap(
                        children: [
                          Text(
                            message.message,
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(width: 10),
                          currentTime(message.timestamp),
                        ],
                      ),
                    if (!hasImage)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMe)
                            Flexible(
                              child: Text(
                                message.senderName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (!isMe) const SizedBox(width: 5),
                          if (!isMe) currentTime(message.timestamp),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
