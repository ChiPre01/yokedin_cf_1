
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yoked_in/chat/user_list_model.dart';
import 'package:yoked_in/chat/user_model.dart';
import 'package:yoked_in/provider/chat_provider.dart';

class UserListTileNotifier extends StateNotifier<UserListTileState> {
  final Ref ref;
  final UserModel user;

  UserListTileNotifier(this.ref, this.user) : super(const UserListTileState()) {
    _checkRelationship();
  }

  Future<void> _checkRelationship() async {
    final chatService = ref.read(chatServiceProvider);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final friends = await chatService.areUsersFriends(currentUserId, user.uid);

    if (friends) {
      state = state.copyWith(
        areFriends: true,
        requestStatus: null,
        isRequestSender: false,
        pendingRequestId: null,
      );
      return;
    }

    final sentRequestId = '${currentUserId}_${user.uid}';
    final receivedRequestId = '${user.uid}_$currentUserId';

    final sentRequestDoc = await FirebaseFirestore.instance
        .collection('messageRequests')
        .doc(sentRequestId)
        .get();

    final receivedRequestDoc = await FirebaseFirestore.instance
        .collection('messageRequests')
        .doc(receivedRequestId)
        .get();

    String? finalStatus;
    bool isSender = false;
    String? requestId;

    if (sentRequestDoc.exists) {
      final sentStatus = sentRequestDoc['status'];
      if (sentStatus == 'pending') {
        finalStatus = 'pending';
        isSender = true;
        requestId = sentRequestId;
      }
    }

    if (receivedRequestDoc.exists && finalStatus == null) {
      final receivedStatus = receivedRequestDoc['status'];
      if (receivedStatus == 'pending') {
        finalStatus = 'pending';
        isSender = false;
        requestId = receivedRequestId;
      }
    }

    state = state.copyWith(
      areFriends: false,
      requestStatus: finalStatus,
      isRequestSender: isSender,
      pendingRequestId: requestId,
    );
  }

  Future<String> sendRequest() async {
    state = state.copyWith(isLoading: true);
    final chatService = ref.read(chatServiceProvider);

    final result = await chatService.sendMessageRequest(
      receiverId: user.uid,
      receiverName: user.name,
      receiverEmail: user.email,
      // photoUrl:  user.photoURL??"",
    );

    if (result == 'success') {
      state = state.copyWith(
        isLoading: false,
        requestStatus: 'pending',
        isRequestSender: true,
        pendingRequestId:
            '${FirebaseAuth.instance.currentUser!.uid}_${user.uid}',
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
    return result;
  }

  Future<String> acceptRequest() async {
    if (state.pendingRequestId == null) return 'no-request';

    state = state.copyWith(isLoading: true);
    final chatService = ref.read(chatServiceProvider);

    final result = await chatService.acceptMessageRequest(
      state.pendingRequestId!,
      user.uid,
    );

    if (result == 'success') {
      state = state.copyWith(
        isLoading: false,
        areFriends: true,
        requestStatus: null,
        isRequestSender: false,
        pendingRequestId: null,
      );

      // Refresh providers
      ref.invalidate(chatsProvider);
      ref.invalidate(requestsProvider);
    } else {
      state = state.copyWith(isLoading: false);
    }

    return result;
  }
}

final userListTileProvider =
    StateNotifierProvider.family<
      UserListTileNotifier,
      UserListTileState,
      UserModel
    >((ref, user) => UserListTileNotifier(ref, user));
