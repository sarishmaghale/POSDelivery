class SharedAuthState {
  bool isLoggingOut = false;
  Future<void> Function()? onUnauthorized;

  void reset() {
    isLoggingOut = false;
  }
}

final sharedAuthState = SharedAuthState();
