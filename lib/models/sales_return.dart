class SalesReturn {
  int? id;
  String? serverId;
  late String customerId;
  late String productId;
  late double quantity;
  String? reason;
  String? remarks;
  late DateTime createdDate;
  bool isSynced = false;

  SalesReturn();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'customer_id': customerId,
      'product_id': productId,
      'quantity': quantity,
      'reason': reason,
      'remarks': remarks,
      'created_date': createdDate.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory SalesReturn.fromMap(Map<String, dynamic> map) {
    final sr = SalesReturn();
    sr.id = map['id'] as int?;
    sr.serverId = map['server_id'] as String?;
    sr.customerId = map['customer_id'] as String;
    sr.productId = map['product_id'] as String;
    sr.quantity = (map['quantity'] as num).toDouble();
    sr.reason = map['reason'] as String?;
    sr.remarks = map['remarks'] as String?;
    sr.createdDate = DateTime.parse(map['created_date'] as String);
    sr.isSynced = (map['is_synced'] as int) == 1;
    return sr;
  }
}
