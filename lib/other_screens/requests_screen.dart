import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:yoked_in/widgets/user_avatar.dart';
import 'package:yoked_in/widgets/utilis.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Refresh request list as soon as screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(requestsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(requestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Requests'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(requestsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // Handle provider states (data, loading, error)
      body: requests.when(
        // ✅ Case 1: Successfully loaded requests
        data: (requestList) {
          if (requestList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          // If requests exist → show list of requests
          return ListView.builder(
            itemCount: requestList.length,
            itemBuilder: (context, index) {
              final request = requestList[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: UserAvatar(
                    photoUrl: request.photoURL,
                    radius: 28,
                    fallbackIcon: Icons.person,
                  ),
                  title: Text(request.senderName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Accept request
                      GestureDetector(
                        onTap: () async {
                          await ref
                              .read(requestsProvider.notifier)
                              .acceptRequest(request.id, request.senderId);

                          if (context.mounted) {
                            showAppSnackbar(
                              context: context,
                              type: SnackbarType.success,
                              description: 'Request accepted!',
                            );

                            // Refresh all providers after accepting
                            ref.invalidate(chatsProvider);
                            ref.invalidate(usersProvider);
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      // ❌ Reject request
                      GestureDetector(
                        onTap: () async {
                          await ref
                              .read(requestsProvider.notifier)
                              .rejectRequest(request.id);

                          if (context.mounted) {
                            showAppSnackbar(
                              context: context,
                              type: SnackbarType.success,
                              description: "Request rejected",
                            );
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        // ✅ Case 2: Loading
        loading: () => const Center(child: CircularProgressIndicator()),
        // ✅ Case 3: Error state
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(requestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
