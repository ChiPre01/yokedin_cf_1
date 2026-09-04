
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupMemberCount extends StatelessWidget {
  final String groupId;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const GroupMemberCount({
    super.key,
    required this.groupId,
    this.style,
    this.prefix = '',
    this.suffix = ' members',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            '$prefix...$suffix',
            style: style ?? const TextStyle(color: Colors.grey),
          );
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>?;
        final memberCount = groupData?['members']?.length ?? 0;

        return Text(
          '$prefix$memberCount$suffix',
          style: style ?? const TextStyle(color: Colors.grey),
        );
      },
    );
  }
}
