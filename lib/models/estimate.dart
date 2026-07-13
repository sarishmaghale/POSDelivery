class Estimate {
  int? id;
  String? serverId;
  late int deliveryId;
  late double grossTotal;
  late double estimatedTotal;
  String? discountType;
  double discountValue = 0;
  double discountAmount = 0;
  String? paymentMode;
  double paidAmount = 0;
  String? remarks;
  late DateTime createdDate;
  bool isSynced = false;

  Estimate();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'delivery_id': deliveryId,
      'gross_total': grossTotal,
      'estimated_total': estimatedTotal,
      'discount_type': discountType,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'payment_mode': paymentMode,
      'paid_amount': paidAmount,
      'remarks': remarks,
      'created_date': createdDate.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    final estimate = Estimate();
    estimate.id = map['id'] as int?;
    estimate.serverId = map['server_id'] as String?;
    estimate.deliveryId = map['delivery_id'] as int;
    estimate.grossTotal = (map['gross_total'] as num?)?.toDouble() ?? 0;
    estimate.estimatedTotal = (map['estimated_total'] as num).toDouble();
    estimate.discountType = map['discount_type'] as String?;
    estimate.discountValue = (map['discount_value'] as num?)?.toDouble() ?? 0;
    estimate.discountAmount = (map['discount_amount'] as num?)?.toDouble() ?? 0;
    estimate.paymentMode = map['payment_mode'] as String?;
    estimate.paidAmount = (map['paid_amount'] as num?)?.toDouble() ?? 0;
    estimate.remarks = map['remarks'] as String?;
    estimate.createdDate = DateTime.parse(map['created_date'] as String);
    estimate.isSynced = (map['is_synced'] as int) == 1;
    return estimate;
  }
}

class EstimateItem {
  int? id;
  late int estimateId;
  late String productId;
  late double quantity;
  late double unitPrice;
  late double lineTotal;
  double discountAmount = 0;
  String? unitId;
  String? unitName;

  EstimateItem();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'estimate_id': estimateId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'discount_amount': discountAmount,
      'unit_id': unitId,
      'unit_name': unitName,
    };
  }

  factory EstimateItem.fromMap(Map<String, dynamic> map) {
    final item = EstimateItem();
    item.id = map['id'] as int?;
    item.estimateId = map['estimate_id'] as int;
    item.productId = map['product_id'] as String;
    item.quantity = (map['quantity'] as num).toDouble();
    item.unitPrice = (map['unit_price'] as num).toDouble();
    item.lineTotal = (map['line_total'] as num).toDouble();
    item.discountAmount = (map['discount_amount'] as num?)?.toDouble() ?? 0;
    item.unitId = map['unit_id'] as String?;
    item.unitName = map['unit_name'] as String?;
    return item;
  }
}
