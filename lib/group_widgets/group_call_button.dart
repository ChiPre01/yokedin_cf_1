
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/chat/user_model.dart';
import 'package:yoked_in/group_chat/group_chat_model.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class GroupCallButton extends ConsumerStatefulWidget {
  final GroupModel group;
  final bool isVideoCall;

  const GroupCallButton({
    super.key,
    required this.group,
    required this.isVideoCall,
  });

  @override
  ConsumerState<GroupCallButton> createState() => _GroupCallButtonState();
}

class _GroupCallButtonState extends ConsumerState<GroupCallButton> {
  List<ZegoUIKitUser> _invitees = [];

  @override
  void initState() {
    super.initState();
    _loadInvitees();
  }

  Future<void> _loadInvitees() async {
    try {
      final currentUserId = ref.read(groupChatServiceProvider).currentUserId;
      final invitees = <ZegoUIKitUser>[];
      print(
        '🔧 Initializing Zego with group name: ${widget.group.groupName}',
      ); // ✅ Debug

      // Get all members except current user
      for (final memberId in widget.group.members) {
        if (memberId != currentUserId) {
          // Fetch user details from Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();

          if (userDoc.exists) {
            final user = UserModel.fromMap(userDoc.data()!);
            invitees.add(ZegoUIKitUser(id: memberId, name: user.name));
          } else {
            // Fallback if user not found
            invitees.add(ZegoUIKitUser(id: memberId, name: 'User'));
          }
        }
      }

      if (mounted) {
        setState(() {
          _invitees = invitees;
        });
      }
    } catch (e) {
      print('Error loading invitees: $e');
      // if (mounted) {
      //   setState(() {
      //   });
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? "Guest";

    return ZegoSendCallInvitationButton(
      iconSize: const Size(30, 30),
      buttonSize: const Size(40, 40),
      isVideoCall: widget.isVideoCall,
      resourceID: "zego_call",
      invitees: _invitees,
      callID: widget.group.groupId,
      timeoutSeconds: 60,
      notificationTitle: widget.group.groupName,
      notificationMessage: widget.isVideoCall
          ? '$userName video calling...'
          : '$userName audio calling...',
      customData: widget.group.groupName, // ✅ Add this line
      // ✅ Add this to override the caller display
      onPressed: (code, message, errorInvitees) async {
        if (code.isEmpty) {
          // Successfully sent invitation
          _showSuccessSnackbar();
          // ✅ Notify group members about the call
          await _notifyGroupMembers();
        } else {
          // Error occurred
          _showErrorSnackbar(message);
        }
      },
    );
  }

  // ✅ Add this method to notify group members
  Future<void> _notifyGroupMembers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Send system message about the call
      await ref
          .read(groupChatServiceProvider)
          .sendGroupMessage(
            groupId: widget.group.groupId,
            message: widget.isVideoCall
                ? '📹 started a video call'
                : '📞 started an audio call',
          );
    } catch (e) {
      print('Error notifying group members: $e');
    }
  }

  void _showSuccessSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Call invitation sent to ${_invitees.length} member${_invitees.length > 1 ? 's' : ''}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send invitation: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
