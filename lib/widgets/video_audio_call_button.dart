
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

ZegoSendCallInvitationButton actionButton(
  bool isVideo,
  String receiverId,
  String receiverName,
  String chatId,
  WidgetRef ref, // Add ref parameter
) => ZegoSendCallInvitationButton(
  iconSize: Size(30, 30),
  buttonSize: Size(40, 40),
  isVideoCall: isVideo,
  resourceID: "zego_call",
  invitees: [ZegoUIKitUser(id: receiverId, name: receiverName)],

  onPressed: (code, message, errorInvitees) {
    final chatService = ref.read(chatServiceProvider);
    chatService.addCallHistory(
      chatId: chatId,
      isVideoCall: isVideo,
      callStatus: '_', // or 'missed' based on actual result
    );
  },
);