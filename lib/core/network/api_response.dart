class ApiResponse<T> {
  final bool status;
  final String? message;
  final T? data;

  ApiResponse({required this.status, this.message, this.data});

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse(
      status: json['Status'] as bool? ?? false,
      message: json['Message'] as String?,
      data: json['Data'] != null && fromJsonT != null
          ? fromJsonT(json['Data'])
          : json['Data'] as T?,
    );
  }
}
