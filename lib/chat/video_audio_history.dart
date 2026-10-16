import 'package:flutter/material.dart';
import 'package:yoked_in/chat/chat_screen.dart';
import 'package:yoked_in/chat/message_model.dart';
import 'package:yoked_in/helper/time_format.dart';
import 'package:yoked_in/widgets/user_avatar.dart';

class VideoAndAudioCallHistory extends StatelessWidget {
  const VideoAndAudioCallHistory({
    super.key,
    required this.isMe,
    required this.widget,
    required this.isMissed,
    required this.isVideo,
    required this.message,
  });

  final bool isMe;
  final ChatScreen widget;
  final bool isMissed;
  final bool isVideo;
  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            UserAvatar(
              photoUrl: widget.otherUser.photoURL,
              radius: 16,
              fallbackIcon: Icons.person,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMissed
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isMissed ? Colors.red : Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVideo ? Icons.videocam : Icons.call,
                  color: isMissed ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMissed
                          ? (isMe ? 'Call not answered' : 'Missed call')
                          : '${isVideo ? 'Video' : 'Audio'} call',
                      style: TextStyle(
                        color: isMissed ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatMessageTime(message.timestamp),
                      style: TextStyle(
                        color: (isMissed ? Colors.red : Colors.green)
                            .withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
