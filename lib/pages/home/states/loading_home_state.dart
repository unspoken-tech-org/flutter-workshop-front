class LoadingHomeState {
  final bool isTableLoading;

  LoadingHomeState({
    this.isTableLoading = false,
  });

  LoadingHomeState copyWith({
    bool? isTableLoading,
  }) {
    return LoadingHomeState(
      isTableLoading: isTableLoading ?? this.isTableLoading,
    );
  }
}
