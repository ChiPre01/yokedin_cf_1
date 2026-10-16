import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/chat/chat_screen.dart';
import 'package:yoked_in/chat/user_model.dart';
import 'package:yoked_in/helper/time_format.dart';
import 'package:yoked_in/other_screens/requests_screen.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:yoked_in/provider/user_status_provider.dart';
import 'package:yoked_in/widgets/user_avatar.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // When screen loads, refresh chat and request providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(chatsProvider);
      ref.invalidate(requestsProvider);
    });
  }

  // Manual refresh (pull-to-refresh action)
  Future<void> _onRefresh() async {
    ref.invalidate(chatsProvider);
    ref.invalidate(requestsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    // Watch chat and request providers
    final chats = ref.watch(chatsProvider);
    final pendingRequests = ref.watch(requestsProvider);
    // Count pending requests
    final requestCount = pendingRequests.when(
      data: (requests) => requests.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Connections',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          // Notification icon (only if there are pending requests)
          if (requestCount > 0)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RequestsScreen()),
              ),
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$requestCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Pull-to-refresh + chat list display
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: chats.when(
          // ✅ Case 1: Chats loaded successfully
          data: (chatList) {
            if (chatList.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Go to Connects tab to send message requests',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            // If chats exist → show chat list
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chatList.length,
              itemBuilder: (context, index) {
                final chat = chatList[index];
                // Fetch other user details
                return FutureBuilder<UserModel?>(
                  future: _getOtherUser(chat.participants),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final otherUser = snapshot.data!;
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) return const SizedBox();
                    // Count unread messages
                    final unreadCount = chat.unreadCount[currentUserId] ?? 0;
                    // Show unread highlight if other user sent message
                    final shouldShowUnread =
                        unreadCount > 0 && chat.lastSenderId != currentUserId;

                    return ListTile(
                      // User profile + online/offline status
                      leading: Stack(
                        children: [
                          UserAvatar(
                            photoUrl: otherUser.photoURL,
                            radius: 20,
                            fallbackIcon: Icons.person,
                          ),
                          // Online/Offline indicator
                          Positioned(
                            bottom: 0,
                            right: 2,
                            child: Consumer(
                              builder: (context, ref, _) {
                                final statusAsync = ref.watch(
                                  userStatusProvider(otherUser.uid),
                                );
                                return statusAsync.when(
                                  data: (isOnline) => CircleAvatar(
                                    radius: 5,
                                    backgroundColor:
                                        isOnline ? Colors.green : Colors.grey,
                                  ),
                                  loading: () => Text(otherUser.email),
                                  error: (_, __) => Text(otherUser.email),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      title: Text(
                        otherUser.name,
                        style: TextStyle(
                          fontWeight: shouldShowUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        chat.lastMessage.isNotEmpty
                            ? chat.lastMessage
                            : "You can now start to chat",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: shouldShowUnread ? Colors.black : Colors.grey,
                          fontWeight: shouldShowUnread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatTime(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  shouldShowUnread ? Colors.blue : Colors.grey,
                            ),
                          ),
                          if (shouldShowUnread)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat.chatId,
                            otherUser: otherUser,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          // ✅ Case 2: Loading state
          loading: () => const Center(child: CircularProgressIndicator()),
          // ✅ Case 3: Error state
          error: (error, _) => ListView(
            children: [
              SizedBox(height: 200),
              Center(
                child: Column(
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _onRefresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method → Get details of the other user in chat
  Future<UserModel?> _getOtherUser(List<String> participants) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;
    final otherUserId = participants.firstWhere((id) => id != currentUserId);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      return doc.exists ? UserModel.fromMap(doc.data()!) : null;
    } catch (e) {
      print('Error getting other user: $e');
      return null;
    }
  }
}
