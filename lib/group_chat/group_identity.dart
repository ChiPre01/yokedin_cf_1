
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoked_in/group_chat/group_chat_model.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';
import 'package:yoked_in/widgets/utilis.dart';

class GroupIdentity extends ConsumerWidget {
  final GroupModel group;
  final bool canEdit;
  final String groupId;

  const GroupIdentity({
    super.key,
    required this.group,
    required this.canEdit,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GestureDetector(
          onTap: canEdit
              ? () => _updateGroupPhoto(context, ref, groupId)
              : null,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: group.groupPhotoURL != null
                    ? NetworkImage(group.groupPhotoURL!)
                    : null,
                child: group.groupPhotoURL == null
                    ? const Icon(Icons.group, size: 60)
                    : null,
              ),
              if (canEdit)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 18,
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!canEdit)
              Text(
                group.groupName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (canEdit)
              GestureDetector(
                onTap: () => _updateGroupName(context, ref, group.groupName),
                child: Text(
                  group.groupName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateGroupPhoto(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      ref.read(groupUpdateLoadingProvider(groupId).notifier).state = true;

      try {
        final imageUrl = await ref
            .read(groupChatServiceProvider)
            .uploadImage(File(pickedFile.path), groupId);

        if (imageUrl.isNotEmpty) {
          await ref
              .read(groupChatServiceProvider)
              .updateGroupInfo(groupId: groupId, newPhotoURL: imageUrl);

          if (context.mounted) {
            // ✅ Set loading to false FIRST
            ref.read(groupUpdateLoadingProvider(groupId).notifier).state =
                false;

            // ✅ THEN invalidate
            ref.invalidate(groupStreamProvider(groupId));
          }
        }
      } finally {
        if (context.mounted) {
          ref.read(groupUpdateLoadingProvider(groupId).notifier).state = false;
        }
      }
    }
  }

  Future<void> _updateGroupName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Group name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (result != null && result.trim().isNotEmpty && result != currentName) {
      ref.read(groupUpdateLoadingProvider(groupId).notifier).state = true;

      try {
        final updateResult = await ref
            .read(groupChatServiceProvider)
            .updateGroupInfo(groupId: groupId, newName: result.trim());

        if (context.mounted) {
          // ✅ Set loading to false FIRST before invalidating
          ref.read(groupUpdateLoadingProvider(groupId).notifier).state = false;

          // ✅ THEN invalidate
          ref.invalidate(groupStreamProvider(groupId));

          final message = updateResult == 'success'
              ? 'Group name updated'
              : 'Failed: $updateResult';
          showAppSnackbar(
            context: context,
            type: SnackbarType.success,
            description: message,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ref.read(groupUpdateLoadingProvider(groupId).notifier).state = false;
          showAppSnackbar(
            context: context,
            type: SnackbarType.error,
            description: "Unable to update a group name",
          );
        }
      }
    }
  }
}
