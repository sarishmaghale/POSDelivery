class EstimateResponse {
  final String estimateId;
  final bool success;
  final String message;

  EstimateResponse({
    required this.estimateId,
    required this.success,
    required this.message,
  });

  factory EstimateResponse.fromJson(Map<String, dynamic> json) {
    return EstimateResponse(
      estimateId: json['estimateId'] as String,
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}
