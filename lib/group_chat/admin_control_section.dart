
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/group_chat/group_chat_model.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';

class AdminControlsSection extends ConsumerWidget {
  final GroupModel group;
  final String groupId;

  const AdminControlsSection({
    super.key,
    required this.group,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Divider(),
        SwitchListTile.adaptive(
          title: const Text('Anyone can edit group info'),
          subtitle: const Text('Allow all members to edit name and photo'),
          value: group.anyoneCanEditInfo,
          onChanged: (value) => _toggleEditPermission(ref, value),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _toggleEditPermission(WidgetRef ref, bool value) async {
    await ref
        .read(groupChatServiceProvider)
        .toggleGroupEditPermission(groupId, value);

    // ✅ Add this invalidation
    ref.invalidate(groupStreamProvider(groupId));
  }
}
