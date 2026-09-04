
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/group_chat/admin_control_section.dart';
import 'package:yoked_in/group_chat/group_identity.dart';
import 'package:yoked_in/group_chat/leave_delete_group.dart';
import 'package:yoked_in/group_chat/member_list_section.dart';
import 'package:yoked_in/group_widgets/add_member_button_section.dart';
import 'package:yoked_in/group_widgets/group_member_count.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';

class GroupInfoScreen extends ConsumerWidget {
  final String groupId;

  const GroupInfoScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Group Info')),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(
              child: Text('Group not found or has been deleted'),
            );
          }

          final isAdmin = group.isAdmin(currentUserId);
          final canEdit = isAdmin || group.anyoneCanEditInfo;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Group photo
                GroupIdentity(group: group, canEdit: canEdit, groupId: groupId),
                const SizedBox(height: 5),
                GroupMemberCount(
                  groupId: groupId,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                // Admin controls
                if (isAdmin)
                  AdminControlsSection(group: group, groupId: groupId),
                // Members list
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                MembersListSection(
                  group: group,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                  groupId: groupId,
                ),
                const SizedBox(height: 20),
                // Add member button
                if (isAdmin || group.anyoneCanEditInfo)
                  AddMemberButtonSection(group: group, groupId: groupId),
                const SizedBox(height: 12),
                // Leave or Delete button
                LeaveAndDeleteGroup(
                  isAdmin: isAdmin,
                  group: group,
                  groupId: groupId,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(groupStreamProvider(groupId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
