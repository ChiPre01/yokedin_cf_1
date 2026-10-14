import 'package:cloud_firestore/cloud_firestore.dart';

class DisplayNameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Makes names case-insensitive while preserving the original display name.
  String normalizeName(String name) => name.trim().toLowerCase();

  /// Returns true if another user's name matches, ignoring capitalization.
  Future<bool> isNameTaken(
    String name, {
    String? excludeUid,
  }) async {
    final normalizedName = normalizeName(name);

    if (normalizedName.isEmpty) {
      return true;
    }

    // Read existing profiles as well as profiles with the new nameKey field.
    // This also supports older profiles that have not been migrated.
    final snapshot = await _users.get();

    for (final document in snapshot.docs) {
      if (excludeUid != null && document.id == excludeUid) {
        continue;
      }

      final data = document.data();
      final existingName = data['name'];

      if (existingName is! String || existingName.trim().isEmpty) {
        continue;
      }

      if (normalizeName(existingName) == normalizedName) {
        return true;
      }
    }

    return false;
  }

  /// Finds the first available name: Sara, Sara1, Sara2, etc.
  Future<String> generateAvailableName(String requestedName) async {
    final baseName = requestedName.trim().isEmpty
        ? 'User'
        : requestedName.trim();

    if (!await isNameTaken(baseName)) {
      return baseName;
    }

    var suffix = 1;

    while (true) {
      final candidate = '$baseName$suffix';

      if (!await isNameTaken(candidate)) {
        return candidate;
      }

      suffix++;
    }
  }

  /// Saves the normalized name alongside the existing profile fields.
  Map<String, dynamic> nameFields(String name) {
    return {
      'name': name.trim(),
      'nameKey': normalizeName(name),
    };
  }
}
