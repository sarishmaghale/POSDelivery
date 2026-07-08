class CartItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discountAmount;

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitPrice = 0,
    this.discountAmount = 0,
  });

  double get grossTotal => quantity * unitPrice;
  double get lineTotal => grossTotal - discountAmount;

  CartItem copyWith({double? quantity, double? unitPrice, double? discountAmount}) {
    return CartItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}
