class CartItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitPrice = 0,
  });

  double get lineTotal => quantity * unitPrice;

  CartItem copyWith({double? quantity, double? unitPrice}) {
    return CartItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
