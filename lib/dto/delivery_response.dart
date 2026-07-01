class DeliveryResponse {
  final String deliveryId;
  final bool success;
  final String message;

  DeliveryResponse({
    required this.deliveryId,
    required this.success,
    required this.message,
  });

  factory DeliveryResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryResponse(
      deliveryId: json['deliveryId'] as String,
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}
