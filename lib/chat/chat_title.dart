
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/chat/chat_screen.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:yoked_in/provider/user_status_provider.dart';
import 'package:yoked_in/widgets/dot_indicator.dart';

class TitleOfChatScreen extends StatelessWidget {
  const TitleOfChatScreen({super.key, required this.widget});

  final ChatScreen widget;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final statusAsync = ref.watch(userStatusProvider(widget.otherUser.uid));
        final typingStatus = ref.watch(typingProvider(widget.chatId));
        final isOtherUserTyping = typingStatus[widget.otherUser.uid] ?? false;

        return statusAsync.when(
          data: (isOnline) => Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.otherUser.photoURL != null
                    ? NetworkImage(widget.otherUser.photoURL!)
                    : null,
                child: widget.otherUser.photoURL == null
                    ? Text(
                        widget.otherUser.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUser.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    // TYPING INDICATOR LOGIC
                    if (isOtherUserTyping)
                      Row(
                        children: [
                          Text(
                            'typing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                          SizedBox(width: 4),
                          ThreeDots(),
                        ],
                      )
                    else if (isOnline)
                      const Text(
                        'Online',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => Text(widget.otherUser.name),
          error: (_, __) => Text(widget.otherUser.name),
        );
      },
    );
  }
}
