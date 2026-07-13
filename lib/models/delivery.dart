class Delivery {
  int? id;
  String? serverId;
  late String customerId;
  late DateTime createdDate;
  String? paymentMode;
  bool isSynced = false;

  Delivery();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'customer_id': customerId,
      'created_date': createdDate.toIso8601String(),
      'payment_mode': paymentMode,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Delivery.fromMap(Map<String, dynamic> map) {
    final delivery = Delivery();
    delivery.id = map['id'] as int?;
    delivery.serverId = map['server_id'] as String?;
    delivery.customerId = map['customer_id'] as String;
    delivery.createdDate = DateTime.parse(map['created_date'] as String);
    delivery.paymentMode = map['payment_mode'] as String?;
    delivery.isSynced = (map['is_synced'] as int) == 1;
    return delivery;
  }
}

class DeliveryItem {
  int? id;
  late int deliveryId;
  late String productId;
  late double quantity;
  late double unitPrice;
  String? unitId;
  String? unit;

  DeliveryItem();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'delivery_id': deliveryId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'unit_id': unitId,
      'unit': unit,
    };
  }

  factory DeliveryItem.fromMap(Map<String, dynamic> map) {
    final item = DeliveryItem();
    item.id = map['id'] as int?;
    item.deliveryId = map['delivery_id'] as int;
    item.productId = map['product_id'] as String;
    item.quantity = (map['quantity'] as num).toDouble();
    item.unitPrice = (map['unit_price'] as num?)?.toDouble() ?? 0;
    item.unitId = map['unit_id'] as String?;
    item.unit = map['unit'] as String?;
    return item;
  }
}
