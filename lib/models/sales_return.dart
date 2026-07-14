import 'payment_entry.dart';

class SalesReturnItem {
  int? id;
  int? salesReturnId;
  late String productId;
  late String productName;
  late double quantity;
  double rate = 0;
  String? unitId;
  String? unit;
  String? discountType;
  double discountValue = 0;
  double discountAmount = 0;

  SalesReturnItem();

  double get lineTotal => (quantity * rate) - discountAmount;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (salesReturnId != null) 'sales_return_id': salesReturnId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'rate': rate,
      if (unitId != null) 'unit_id': unitId,
      if (unit != null) 'unit': unit,
      if (discountType != null) 'discount_type': discountType,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
    };
  }

  factory SalesReturnItem.fromMap(Map<String, dynamic> map) {
    final item = SalesReturnItem();
    item.id = map['id'] as int?;
    item.salesReturnId = map['sales_return_id'] as int?;
    item.productId = map['product_id'] as String;
    item.productName = map['product_name'] as String;
    item.quantity = (map['quantity'] as num).toDouble();
    item.rate = (map['rate'] as num?)?.toDouble() ?? 0;
    item.unitId = map['unit_id'] as String?;
    item.unit = map['unit'] as String?;
    item.discountType = map['discount_type'] as String?;
    item.discountValue = (map['discount_value'] as num?)?.toDouble() ?? 0;
    item.discountAmount = (map['discount_amount'] as num?)?.toDouble() ?? 0;
    return item;
  }
}

class SalesReturn {
  int? id;
  String? serverId;
  late String customerId;
  String? reason;
  String? remarks;
  late DateTime createdDate;
  bool isSynced = false;
  List<SalesReturnItem> items = [];
  String? discountType;
  double discountValue = 0;
  double discountAmount = 0;
  String? paymentMode;
  List<PaymentEntry> paymentEntries = [];

  SalesReturn();

  double get grossTotal =>
      items.fold<double>(0, (sum, item) => sum + item.quantity * item.rate);

  double get totalItemDiscount =>
      items.fold<double>(0, (sum, item) => sum + item.discountAmount);

  double get netTotal => grossTotal - totalItemDiscount - discountAmount;

  double get netTotalBeforeHeaderDiscount => grossTotal - totalItemDiscount;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'customer_id': customerId,
      'reason': reason,
      'remarks': remarks,
      'created_date': createdDate.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      if (discountType != null) 'discount_type': discountType,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      if (paymentMode != null) 'payment_mode': paymentMode,
      'payment_entries': PaymentEntry.listToJson(paymentEntries),
    };
  }

  factory SalesReturn.fromMap(Map<String, dynamic> map) {
    final sr = SalesReturn();
    sr.id = map['id'] as int?;
    sr.serverId = map['server_id'] as String?;
    sr.customerId = map['customer_id'] as String;
    sr.reason = map['reason'] as String?;
    sr.remarks = map['remarks'] as String?;
    sr.createdDate = DateTime.parse(map['created_date'] as String);
    sr.isSynced = (map['is_synced'] as int) == 1;
    sr.discountType = map['discount_type'] as String?;
    sr.discountValue = (map['discount_value'] as num?)?.toDouble() ?? 0;
    sr.discountAmount = (map['discount_amount'] as num?)?.toDouble() ?? 0;
    sr.paymentMode = map['payment_mode'] as String?;
    sr.paymentEntries = PaymentEntry.listFromJson(map['payment_entries'] as String?);
    return sr;
  }
}
