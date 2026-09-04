
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';

class ImagePreviewDialog extends ConsumerWidget {
  final File imageFile;
  final String groupId;

  const ImagePreviewDialog({
    super.key,
    required this.imageFile,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploading = ref.watch(isUploadingProvider(groupId));

    return AlertDialog(
      title: const Text('Send Image?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(imageFile, height: 250, fit: BoxFit.cover),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isUploading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isUploading ? null : () => Navigator.pop(context, true),
          child: isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}
