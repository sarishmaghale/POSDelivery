class SalesInvoiceResponse {
  final bool success;
  final String message;
  final String? invoiceId;

  SalesInvoiceResponse({
    required this.success,
    required this.message,
    this.invoiceId,
  });

  factory SalesInvoiceResponse.fromJson(Map<String, dynamic> json) {
    final status = json['Status'] as bool? ?? false;
    final data = json['Data'];
    String? id;
    if (data is Map<String, dynamic>) {
      id = (data['TransactionId'] ?? data['Id']) as String?;
    }
    return SalesInvoiceResponse(
      success: status,
      message: json['Message'] as String? ?? '',
      invoiceId: id,
    );
  }
}
