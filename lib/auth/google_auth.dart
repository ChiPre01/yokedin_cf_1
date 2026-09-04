class GoogleAuthState {
  final bool isLoading;
  final String? error;

  GoogleAuthState({this.isLoading = false, this.error});

  GoogleAuthState copyWith({bool? isLoading, String? error}) {
    return GoogleAuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
