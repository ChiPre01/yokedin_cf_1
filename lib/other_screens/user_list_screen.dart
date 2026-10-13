
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:yoked_in/widgets/user_list_tile.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    // Force refresh when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(usersProvider);
    });
  }

  Future<void> _onRefresh() async {
    // Clear friendship cache before refreshing
    ref.invalidate(usersProvider);
    ref.invalidate(requestsProvider);
    // Wait a bit for the providers to refresh
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auto-refresh provider to trigger refreshes
    ref.watch(autoRefreshProvider);
    final users = ref.watch(filteredUsersProvider);

    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Build Connections'),
        backgroundColor: Colors.white,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () =>
                            ref.read(searchQueryProvider.notifier).state = '',
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        backgroundColor: Colors.white,
        child: users.when(
          data: (userList) {
            if (userList.isEmpty && searchQuery.isNotEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No users found matching your search')),
                ],
              );
            }

            if (userList.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No other users found')),
                ],
              );
            }

            return ListView.builder(
              // Enable pull-to-refresh
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
                return UserListTile(user: user);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: 200),
              Center(
                child: Column(
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(usersProvider),
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
}
