
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoked_in/auth/zego_secret_key.dart';
import 'package:yoked_in/group_chat/group_chat_model.dart';
import 'package:yoked_in/group_chat/group_chat_services.dart';
import 'package:yoked_in/group_chat/group_info_screen.dart';
import 'package:yoked_in/group_widgets/chat_input_bar.dart';
import 'package:yoked_in/group_widgets/chat_message_list.dart';
import 'package:yoked_in/group_widgets/group_call_button.dart';
import 'package:yoked_in/group_widgets/group_member_count.dart';
import 'package:yoked_in/group_widgets/image_preview.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';
import 'package:yoked_in/widgets/dot_indicator.dart';
import 'package:yoked_in/widgets/utilis.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreen();
}

class _GroupChatScreen extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeZego();
    _checkMembership();
    _markMessagesAsRead();
  }

  Future<void> _initializeZego() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: ZegoConfig.appID,
        appSign: ZegoConfig.appSign,
        userID: user.uid,
        userName: widget.group.groupName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );
    } catch (e) {
      print('Error initializing Zego: $e');
    }
  }

  void _checkMembership() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if (!widget.group.members.contains(currentUserId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        showAppSnackbar(
          context: context,
          type: SnackbarType.success,
          description: 'You are no longer a member of this group',
        );
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    await ref
        .read(groupChatServiceProvider)
        .markGroupMessagesAsRead(widget.group.groupId);
  }

  void _onTextChanged(String text) {
    if (!mounted) return;
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref
          .read(groupTypingProvider(widget.group.groupId).notifier)
          .setTyping(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_isTyping) {
        _isTyping = false;
        ref
            .read(groupTypingProvider(widget.group.groupId).notifier)
            .setTyping(false);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _isTyping = false;
    ref
        .read(groupTypingProvider(widget.group.groupId).notifier)
        .setTyping(false);

    final result = await ref
        .read(groupChatServiceProvider)
        .sendGroupMessage(groupId: widget.group.groupId, message: text);

    if (result != 'success' && mounted) {
      showAppSnackbar(
        context: context,
        type: SnackbarType.error,
        description: "Unable to complete a process",
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      _showImagePreviewDialog(File(pickedFile.path));
    }
  }

  void _showImagePreviewDialog(File imageFile) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => ImagePreviewDialog(
        imageFile: imageFile,
        groupId: widget.group.groupId,
      ),
    );

    if (result == true && mounted) {
      await _uploadAndSendImage(imageFile);
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    if (!mounted) return;

    ref.read(isUploadingProvider(widget.group.groupId).notifier).state = true;

    try {
      final imageUrl = await ref
          .read(groupChatServiceProvider)
          .uploadImage(imageFile, widget.group.groupId);

      if (!mounted) return;

      if (imageUrl.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));

        await ref
            .read(groupChatServiceProvider)
            .sendGroupImageMessage(
              groupId: widget.group.groupId,
              imageUrl: imageUrl,
            );

        if (!mounted) return;
        showAppSnackbar(
          context: context,
          type: SnackbarType.success,
          description: 'Image sent successfully',
        );
      } else {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: 'Failed to upload image',
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: "Unable to complete a process",
        );
      }
    } finally {
      if (mounted) {
        ref.read(isUploadingProvider(widget.group.groupId).notifier).state =
            false;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();

    try {
      GroupChatService().markGroupMessagesAsRead(widget.group.groupId);
      GroupChatService().setGroupTypingStatus(widget.group.groupId, false);
    } catch (e) {
      // Ignore errors during disposal
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typingUsers = ref.watch(
      groupTypingUsersProvider(widget.group.groupId),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          GroupCallButton(group: widget.group, isVideoCall: false),
          GroupCallButton(group: widget.group, isVideoCall: true),
          const SizedBox(width: 8),
        ],
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GroupInfoScreen(groupId: widget.group.groupId),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.group.groupPhotoURL != null
                    ? NetworkImage(widget.group.groupPhotoURL!)
                    : null,
                child: widget.group.groupPhotoURL == null
                    ? const Icon(Icons.group)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.groupName,
                      style: const TextStyle(fontSize: 16),
                    ),
                    typingUsers.isNotEmpty
                        ? Row(
                            children: [
                              Text(
                                "Typing",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                              ThreeDots(),
                            ],
                          )
                        : GroupMemberCount(
                            groupId: widget.group.groupId,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                            suffix: ' members',
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessagesList(
              groupId: widget.group.groupId,
              scrollController: _scrollController,
            ),
          ),
          ChatInputBar(
            groupId: widget.group.groupId,
            messageController: _messageController,
            onTextChanged: _onTextChanged,
            onSendMessage: _sendMessage,
            onSendImage: _sendImage,
          ),
        ],
      ),
    );
  }
}
