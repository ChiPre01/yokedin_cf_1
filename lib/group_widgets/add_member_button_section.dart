import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/chat/user_model.dart';
import 'package:yoked_in/group_chat/group_chat_model.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';
import 'package:yoked_in/widgets/user_avatar.dart';
import 'package:yoked_in/widgets/utilis.dart';

class AddMemberButtonSection extends ConsumerWidget {
  final GroupModel group;
  final String groupId;

  const AddMemberButtonSection({
    super.key,
    required this.group,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showAddMemberDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final availableUsers = await ref.read(
        availableMembersProvider(groupId).future,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      if (availableUsers.isEmpty) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.success,
          description:
              'No friends available to add, First make a friends to add',
        );

        return;
      }

      if (!context.mounted) return;
      _showMembersListDialog(context, ref, availableUsers);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      showAppSnackbar(
        context: context,
        type: SnackbarType.error,
        description: "Unable to complete a process",
      );
    }
  }

  Future<void> _showMembersListDialog(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> availableUsers,
  ) async {
    final chatService = ref.read(groupChatServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableUsers.length,
            itemBuilder: (context, index) {
              final user = availableUsers[index];
              return ListTile(
                leading: UserAvatar(
                  photoUrl: user.photoURL,
                  radius: 20,
                  fallbackIcon: Icons.person,
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () async {
                  Navigator.pop(context);

                  final result = await chatService.addGroupMember(
                    groupId: groupId,
                    userId: user.uid,
                    userName: user.name,
                  );

                  if (context.mounted) {
                    final message = result == 'success'
                        ? '${user.name} added to group'
                        : result;
                    showAppSnackbar(
                      context: context,
                      type: SnackbarType.success,
                      description: message,
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
