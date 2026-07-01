class DriverStock {
  int? id;
  late String productId;
  late double assignedQuantity;
  double deliveredQuantity = 0;

  DriverStock();

  double get remainingQuantity => assignedQuantity - deliveredQuantity;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'assigned_quantity': assignedQuantity,
      'delivered_quantity': deliveredQuantity,
    };
  }

  factory DriverStock.fromMap(Map<String, dynamic> map) {
    final stock = DriverStock();
    stock.id = map['id'] as int?;
    stock.productId = map['product_id'] as String;
    stock.assignedQuantity = (map['assigned_quantity'] as num).toDouble();
    stock.deliveredQuantity = (map['delivered_quantity'] as num?)?.toDouble() ?? 0;
    return stock;
  }
}
