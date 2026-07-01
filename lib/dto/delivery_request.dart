class DeliveryRequest {
  final String customerId;
  final List<DeliveryItemRequest> items;

  DeliveryRequest({
    required this.customerId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class DeliveryItemRequest {
  final String productId;
  final double quantity;
  final double unitPrice;

  DeliveryItemRequest({
    required this.productId,
    required this.quantity,
    this.unitPrice = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
