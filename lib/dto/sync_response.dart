class SyncResponse {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResponse({
    required this.success,
    required this.message,
    required this.syncedCount,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      syncedCount: json['syncedCount'] as int,
    );
  }
}
