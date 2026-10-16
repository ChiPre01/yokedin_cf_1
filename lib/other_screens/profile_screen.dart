import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoked_in/auth/google_auth_service.dart';
import 'package:yoked_in/auth/user_login_screen.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:yoked_in/provider/user_list_provider.dart';
import 'package:yoked_in/provider/user_profile_provider.dart';
import 'package:yoked_in/services/cloudflare_media_service.dart';
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

    // Refresh the profile when the signed-in user changes.
    if (currentUser?.uid != lastUserId) {
      lastUserId = currentUser?.uid;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.refresh();
        }
      });
    }

    if (profile.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
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
                    backgroundColor: Colors.grey.shade200,
                    child: ClipOval(
                      child: profile.photoUrl == null ||
                              profile.photoUrl!.isEmpty
                          ? const SizedBox(
                              width: 120,
                              height: 120,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            )
                          : _ProfileAvatarImage(
                              key: ValueKey(profile.photoUrl),
                              url: profile.photoUrl!,
                              size: 120,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final success =
                            await notifier.updateProfilePicture();

                        if (!context.mounted) return;

                        if (success) {
                          showAppSnackbar(
                            context: context,
                            type: SnackbarType.success,
                            description:
                                'Profile picture changed successfully!',
                          );
                        } else {
                          showAppSnackbar(
                            context: context,
                            type: SnackbarType.error,
                            description:
                                'Failed to update profile picture',
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
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                profile.name ?? 'No Name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                profile.email ?? 'No Email',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              Text(
                'Joined ${profile.createdAt != null ? DateFormat("MMM d, y").format(profile.createdAt!) : "Joined date not available"}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              MaterialButton(
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text(
                        'Are you sure you want to logout?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await FirebaseServices().signOut();

                    if (!mounted) return;

                    ref.invalidate(usersProvider);
                    ref.invalidate(requestsProvider);
                    ref.invalidate(chatsProvider);
                    ref.invalidate(searchQueryProvider);
                    ref.invalidate(filteredUsersProvider);
                    ref.invalidate(profileProvider);
                    ref.invalidate(userListTileProvider);

                    if (!context.mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserLoginScreen(),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Log out',
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

/// Loads Cloudflare media with Firebase authentication.
///
/// Existing Firebase Storage download URLs continue to use Image.network.
class _ProfileAvatarImage extends StatefulWidget {
  final String url;
  final double size;

  const _ProfileAvatarImage({
    super.key,
    required this.url,
    required this.size,
  });

  @override
  State<_ProfileAvatarImage> createState() =>
      _ProfileAvatarImageState();
}

class _ProfileAvatarImageState extends State<_ProfileAvatarImage> {
  late Future<Uint8List>? _imageFuture;

  bool get _isCloudflareUrl {
    final uri = Uri.tryParse(widget.url);
    final baseUri = Uri.parse(CloudflareMediaService.baseUrl);

    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == baseUri.host &&
        uri.port == baseUri.port &&
        uri.path.startsWith('/media/');
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    if (_isCloudflareUrl) {
      _imageFuture =
          CloudflareMediaService.instance.downloadMedia(widget.url);
    } else {
      _imageFuture = null;
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCloudflareUrl) {
      return Image.network(
        widget.url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    }

    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildFallback();
        }

        return Image.memory(
          snapshot.data!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback();
          },
        );
      },
    );
  }

  Widget _buildFallback() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: const Center(
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
}
