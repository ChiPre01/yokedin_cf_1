
// -------------------- CHAT SERVICE --------------------
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yoked_in/chat/chat_services.dart';
import 'package:yoked_in/chat/model.dart';
import 'package:yoked_in/chat/user_model.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// -------------------- AUTH STATE --------------------
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// -------------------- USERS --------------------
class UsersNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final ChatService _chatService;
  StreamSubscription<List<UserModel>>? _subscription;

  UsersNotifier(this._chatService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription?.cancel();
    _subscription = _chatService.getAllUsers().listen(
      (users) => state = AsyncValue.data(users),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  void refresh() => _init();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final usersProvider =
    StateNotifierProvider<UsersNotifier, AsyncValue<List<UserModel>>>((ref) {
      final service = ref.watch(chatServiceProvider);
      return UsersNotifier(service);
    });

// -------------------- REQUESTS --------------------
class RequestsNotifier
    extends StateNotifier<AsyncValue<List<MessageRequestModel>>> {
  final ChatService _chatService;
  StreamSubscription<List<MessageRequestModel>>? _subscription;

  RequestsNotifier(this._chatService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription?.cancel();

    _subscription = _chatService.getPendingRequests().listen(
      (requests) => state = AsyncValue.data(requests),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  Future<void> acceptRequest(String requestId, String senderId) async {
    await _chatService.acceptMessageRequest(requestId, senderId);
    _init();
  }

  Future<void> rejectRequest(String requestId) async {
    await _chatService.rejectMessageRequest(requestId);
    _init();
  }

  void refresh() => _init();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final requestsProvider =
    StateNotifierProvider<
      RequestsNotifier,
      AsyncValue<List<MessageRequestModel>>
    >((ref) {
      final service = ref.watch(chatServiceProvider);
      return RequestsNotifier(service);
    });

// -------------------- CHATS --------------------
class ChatsNotifier extends StateNotifier<AsyncValue<List<ChatModel>>> {
  final ChatService _chatService;
  StreamSubscription<List<ChatModel>>? _subscription;

  ChatsNotifier(this._chatService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription?.cancel();

    _subscription = _chatService.getUserChats().listen(
      (chats) => state = AsyncValue.data(chats),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  void refresh() => _init();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final chatsProvider =
    StateNotifierProvider<ChatsNotifier, AsyncValue<List<ChatModel>>>((ref) {
      final service = ref.watch(chatServiceProvider);
      return ChatsNotifier(service);
    });

// -------------------- SEARCH --------------------
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredUsersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final users = ref.watch(usersProvider);
  final query = ref.watch(searchQueryProvider);
  return users.when(
    data: (list) {
      if (query.isEmpty) return AsyncValue.data(list);
      return AsyncValue.data(
        list
            .where(
              (u) =>
                  u.name.toLowerCase().contains(query.toLowerCase()) ||
                  u.email.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// -------------------- AUTO REFRESH ON AUTH CHANGE --------------------
final autoRefreshProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
    next.whenData((user) {
      if (user != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.invalidate(usersProvider);
          ref.invalidate(requestsProvider);
          ref.invalidate(chatsProvider);
        });
      }
    });
  });
});

// -------------------- TYPING INDICATOR --------------------
class TypingNotifier extends StateNotifier<Map<String, bool>> {
  final ChatService _chatService;
  StreamSubscription<Map<String, bool>>? _subscription;
  final String chatId;

  TypingNotifier(this._chatService, this.chatId) : super({}) {
    _listenToTypingStatus();
  }

  void _listenToTypingStatus() {
    _subscription?.cancel();
    _subscription = _chatService
        .getTypingStatus(chatId)
        .listen(
          (typingData) => state = Map<String, bool>.from(typingData),
          onError: (e) => state = {},
        );
  }

  Future<void> setTyping(bool isTyping) async {
    await _chatService.setTypingStatus(chatId, isTyping);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final typingProvider =
    StateNotifierProvider.family<TypingNotifier, Map<String, bool>, String>((
      ref,
      chatId,
    ) {
      final service = ref.watch(chatServiceProvider);
      return TypingNotifier(service, chatId);
    });
