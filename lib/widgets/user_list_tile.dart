import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/chat/chat_screen.dart';
import 'package:yoked_in/chat/user_list_model.dart';
import 'package:yoked_in/chat/user_model.dart';
import 'package:yoked_in/helper/navigation_helper.dart';
import 'package:yoked_in/provider/user_list_provider.dart';
import 'package:yoked_in/provider/user_status_provider.dart';
import 'package:yoked_in/widgets/user_avatar.dart';
import 'package:yoked_in/widgets/utilis.dart';

class UserListTile extends ConsumerWidget {
  final UserModel user;

  const UserListTile({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userListTileProvider(user));
    final notifier = ref.read(userListTileProvider(user).notifier);

    return ListTile(
      // Profile picture or fallback (first letter of name)
      leading: UserAvatar(
        photoUrl: user.photoURL,
        radius: 20,
        fallbackIcon: Icons.person,
      ),
      title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      // Show online/offline status in subtitle
      subtitle: Consumer(
        builder: (context, ref, _) {
          final statusAsync = ref.watch(userStatusProvider(user.uid));
          return statusAsync.when(
            data: (isOnline) => Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
            loading: () => Text(user.email),
            error: (_, __) => Text(user.email),
          );
        },
      ),
      // Right-side action button (chat, add friend, accept request, etc.)
      trailing: _buildTrailingWidget(context, ref, state, notifier),
    );
  }

  Widget _buildTrailingWidget(
    BuildContext context,
    WidgetRef ref,
    UserListTileState state,
    UserListTileNotifier notifier,
  ) {
    if (state.isLoading) {
      // Show loading spinner while checking status
      return const SizedBox(
        width: 20,
        height: 20,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    // Already friends → Show "Chat" button
    if (state.areFriends) {
      return MaterialButton(
        color: Colors.green,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: () => _navigateToChat(context),
        child: buttonName(Icons.chat, "Connected"),
      );
    }
    // Current user SENT the request → Show "Pending"
    if (state.requestStatus == 'pending') {
      if (state.isRequestSender) {
        return ElevatedButton(
          onPressed: null,
          child: SizedBox(
            width: 100,
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions, color: Colors.black, size: 20),
                SizedBox(width: 5),
                Text(
                  "Pending",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Current user RECEIVED the request → Show "Accept" button
        return MaterialButton(
          color: Colors.orange,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onPressed: () async {
            final result = await notifier.acceptRequest();
            if (result == 'success' && context.mounted) {
              showAppSnackbar(
                context: context,
                type: SnackbarType.success,
                description: 'Request accepted!',
              );
            } else {
              if (context.mounted) {
                showAppSnackbar(
                  context: context,
                  type: SnackbarType.error,
                  description: 'Failed: $result',
                );
              }
            }
          },
          child: buttonName(Icons.done, "Accept"),
        );
      }
    }
    // Default → Not friends yet → Show "Add Friend" button
    return MaterialButton(
      color: Colors.blueAccent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () async {
        final result = await notifier.sendRequest();
        if (result == 'success' && context.mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.success,
            description: 'Request sent successfully!',
          );
        } else {
          if (context.mounted) {
            showAppSnackbar(
              context: context,
              type: SnackbarType.error,
              description: result,
            );
          }
        }
      },
      child: buttonName(Icons.person_add, "Click To Connect"),
    );
  }

  SizedBox buttonName(IconData icon, String name) {
    return SizedBox(
      width: 150,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to chat screen when "Chat" button clicked
  Future<void> _navigateToChat(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final chatId = _generateChatId(currentUserId, user.uid);
    NavigationHelper.push(context, ChatScreen(chatId: chatId, otherUser: user));
  }

  // Generate unique chatId between two users
  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }
}
