
import 'package:flutter/material.dart';
import 'package:yoked_in/chat/chat_screen.dart';
import 'package:yoked_in/chat/message_model.dart';
import 'package:yoked_in/helper/current_time.dart';
import 'package:yoked_in/helper/time_format.dart';
import 'package:yoked_in/widgets/full_screen_image.dart';
import 'package:yoked_in/widgets/message_status_icon.dart';

class MessageAndImageDisplay extends StatelessWidget {
  const MessageAndImageDisplay({
    super.key,
    required this.isMe,
    required this.widget,
    required this.message,
  });

  final bool isMe;
  final ChatScreen widget;
  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    final hasText = message.message.isNotEmpty;
    final hasBoth = hasImage && hasText;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherUser.photoURL != null
                  ? NetworkImage(widget.otherUser.photoURL!)
                  : null,
              child: widget.otherUser.photoURL == null
                  ? Text(
                      widget.otherUser.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: message.type == 'image' ? 8 : 10,
                vertical: message.type == 'image' ? 4 : 10,
              ),
              decoration: BoxDecoration(
                color: isMe && message.type != 'image'
                    ? Colors.blue
                    : message.type == 'image'
                    ? Colors.white
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Image display
                  if (message.type == 'image' && message.imageUrl != null) ...[
                    // ClipRRect(
                    //   borderRadius: BorderRadius.circular(16),
                    //   child: GestureDetector(
                    //     onTap: () =>
                    //         showFullScreenImage(message.imageUrl!, context),
                    //     child: Container(
                    //       constraints: const BoxConstraints(
                    //         maxWidth: 250,
                    //         maxHeight: 300,
                    //       ),
                    //       child: Image.network(
                    //         message.imageUrl!,
                    //         fit: BoxFit.cover,
                    //         loadingBuilder: (context, child, loadingProgress) {
                    //           if (loadingProgress == null) return child;
                    //           return SizedBox(
                    //             height: 200,
                    //             child: Center(
                    //               child: CircularProgressIndicator(
                    //                 value:
                    //                     loadingProgress.expectedTotalBytes !=
                    //                         null
                    //                     ? loadingProgress
                    //                               .cumulativeBytesLoaded /
                    //                           loadingProgress
                    //                               .expectedTotalBytes!
                    //                     : null,
                    //               ),
                    //             ),
                    //           );
                    //         },
                    //         errorBuilder: (context, error, stackTrace) {
                    //           return Container(
                    //             height: 200,
                    //             color: Colors.grey[300],
                    //             child: const Icon(
                    //               Icons.broken_image,
                    //               size: 50,
                    //               color: Colors.grey,
                    //             ),
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              showFullScreenImage(message.imageUrl!, context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.network(
                              message.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
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
                            child: Row(
                              children: [
                                currentTime(message.timestamp),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  buildMessageStatusIcon(
                                    message,
                                    widget.otherUser.uid,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (message.message.isNotEmpty) const SizedBox(height: 8),
                  ],
                  // Text message (for regular messages or image captions)
                  // if (message.message.isNotEmpty)
                  //   Text(
                  //     message.message,
                  //     style: TextStyle(
                  //       color: isMe ? Colors.white : Colors.black87,
                  //     ),
                  //   ),
                  if (message.message.isNotEmpty)
                    Text(
                      message.message,
                      style: TextStyle(
                        color: hasBoth
                            ? Colors.black
                            : (isMe ? Colors.white : Colors.black87),
                      ),
                    ),
                  SizedBox(height: 4),
                  if (message.message.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isMe)
                          Text(
                            formatMessageTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white : Colors.black54,
                            ),
                          ),
                        if (!hasBoth)
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            buildMessageStatusIcon(
                              message,
                              widget.otherUser.uid,
                            ),
                          ],
                      ],
                    ),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
