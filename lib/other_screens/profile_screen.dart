
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoked_in/auth/google_auth_service.dart';
import 'package:yoked_in/auth/user_login_screen.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:yoked_in/provider/user_list_provider.dart';
import 'package:yoked_in/provider/user_profile_provider.dart';
import 'package:yoked_in/widgets/utilis.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? lastUserId;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if user has changed and refresh if needed
    if (currentUser?.uid != lastUserId) {
      lastUserId = currentUser?.uid;
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.refresh();
        }
      });
    }
    if (profile.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Add a refresh button as additional option
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refresh(),
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  Positioned(
                    bottom: 5,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final success = await notifier.updateProfilePicture();
                        if (success && context.mounted) {
                          showAppSnackbar(
                            context: context,
                            type: SnackbarType.success,
                            description:
                                "Profile picture changed successfully!",
                          );
                        } else if (context.mounted) {
                          showAppSnackbar(
                            context: context,
                            type: SnackbarType.error,
                            description: "Failed to update profile picture",
                          );
                        }
                      },
                      child: const CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.black,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (profile.isUploading)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                profile.name ?? "No Name",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                profile.email ?? "No Email",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              // Display date
              Text(
                "Joined ${profile.createdAt != null ? DateFormat("MMM d, y").format(profile.createdAt!) : "Joined date not available"}",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              MaterialButton(
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: () async {
                  // Show confirmation dialog before logging out
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    // Perform logout
                    await FirebaseServices().signOut();

                    // Invalidate all providers
                    ref.invalidate(usersProvider);
                    ref.invalidate(requestsProvider);
                    ref.invalidate(chatsProvider);
                    ref.invalidate(searchQueryProvider);
                    ref.invalidate(filteredUsersProvider);
                    ref.invalidate(profileProvider);
                    ref.invalidate(userListTileProvider);

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserLoginScreen(),
                        ),
                      );
                    }
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        "Log out",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
