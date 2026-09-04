
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoked_in/provider/chat_provider.dart';
import 'package:yoked_in/provider/group_chat_provider.dart';
import 'package:yoked_in/widgets/utilis.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _selectedMembers = <String>{};
  File? _groupImage;
  bool _isCreating = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _groupImage = File(pickedFile.path));
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      showAppSnackbar(
        context: context,
        type: SnackbarType.error,
        description: 'Please enter group name',
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      showAppSnackbar(
        context: context,
        type: SnackbarType.error,
        description: 'Please select at least one member other then you',
      );
      return;
    }

    setState(() => _isCreating = true);

    final chatService = ref.read(groupChatServiceProvider);
    String? photoURL;

    // Upload group image if selected
    if (_groupImage != null) {
      photoURL = await chatService.uploadImage(
        _groupImage!,
        'group_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    final result = await chatService.createGroup(
      groupName: _nameController.text.trim(),
      memberIds: _selectedMembers.toList(),
      groupPhotoURL: photoURL,
    );

    setState(() => _isCreating = false);

    if (result == 'success' && mounted) {
      ref.invalidate(groupsProvider);
      Navigator.pop(context);
      showAppSnackbar(
        context: context,
        type: SnackbarType.success,
        description: 'Group created successfully',
      );
    } else if (mounted) {
      showAppSnackbar(
        context: context,
        type: SnackbarType.error,
        description: result,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _createGroup, child: const Text('Create')),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Group image
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _groupImage != null
                  ? FileImage(_groupImage!)
                  : null,
              child: _groupImage == null
                  ? const Icon(Icons.add_a_photo, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          // Group name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Members (Friends Only)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Member selection
          Expanded(
            child: users.when(
              data: (userList) {
                if (userList.isEmpty) {
                  return const Center(child: Text('No friends available'));
                }

                return ListView.builder(
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    final isSelected = _selectedMembers.contains(user.uid);

                    return FutureBuilder<bool>(
                      future: ref
                          .read(groupChatServiceProvider)
                          .areUsersFriends(
                            ref.read(groupChatServiceProvider).currentUserId,
                            user.uid,
                          ),
                      builder: (context, snapshot) {
                        if (snapshot.data != true) return const SizedBox();

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMembers.add(user.uid);
                              } else {
                                _selectedMembers.remove(user.uid);
                              }
                            });
                          },
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          secondary: CircleAvatar(
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Text(user.name[0].toUpperCase())
                                : null,
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
