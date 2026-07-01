class EstimateRequest {
  final String deliveryId;
  final List<EstimateItemRequest> items;
  final double estimatedTotal;
  final String? paymentMode;
  final double? paidAmount;
  final String? remarks;
  final String? discountType;
  final double? discountValue;
  final double? discountAmount;

  EstimateRequest({
    required this.deliveryId,
    required this.items,
    required this.estimatedTotal,
    this.paymentMode,
    this.paidAmount,
    this.remarks,
    this.discountType,
    this.discountValue,
    this.discountAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'deliveryId': deliveryId,
      'items': items.map((e) => e.toJson()).toList(),
      'estimatedTotal': estimatedTotal,
      'paymentMode': paymentMode,
      'paidAmount': paidAmount,
      'remarks': remarks,
      'discountType': discountType,
      'discountValue': discountValue,
      'discountAmount': discountAmount,
    };
  }
}

class EstimateItemRequest {
  final String productId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  EstimateItemRequest({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
    };
  }
}
