/// Profile state model
class ProfileState {
  final String? photoUrl;
  final String? name;
  final String? email;
  final bool isLoading;
  final bool isUploading;
  final DateTime? createdAt;
  final String? userId; // Add userId to track current user

  ProfileState({
    this.photoUrl,
    this.name,
    this.createdAt,
    this.email,
    this.isLoading = false,
    this.isUploading = false,
    this.userId,
  });

  ProfileState copyWith({
    String? photoUrl,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? isLoading,
    bool? isUploading,
    String? userId,
  }) {
    return ProfileState(
      photoUrl: photoUrl ?? this.photoUrl,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      userId: userId ?? this.userId,
    );
  }
}
