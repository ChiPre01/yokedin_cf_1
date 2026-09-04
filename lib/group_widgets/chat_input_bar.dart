
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';

class ChatInputBar extends ConsumerWidget {
  final String groupId;
  final TextEditingController messageController;
  final Function(String) onTextChanged;
  final VoidCallback onSendMessage;
  final VoidCallback onSendImage;

  const ChatInputBar({
    super.key,
    required this.groupId,
    required this.messageController,
    required this.onTextChanged,
    required this.onSendMessage,
    required this.onSendImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploading = ref.watch(isUploadingProvider(groupId));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isUploading ? null : onSendImage,
            icon: Icon(
              Icons.image,
              color: isUploading ? Colors.grey : Colors.blue,
            ),
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              onChanged: onTextChanged,
              enabled: !isUploading,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: isUploading ? null : onSendMessage,
            mini: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.blueAccent, size: 30),
          ),
        ],
      ),
    );
  }
}
