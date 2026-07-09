import 'dart:convert';

class Product {
  int? id;
  late String serverId;
  late String categoryId;
  late String name;
  String? japaneseName;
  late double unitPrice;
  double stock = 0;
  String? unitId;
  String? unit;
  String? imageUrl;
  List<String> productImages = [];
  String? description;
  int taxable = 0;
  String? chalanNumber;

  Product();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'category_id': categoryId,
      'name': name,
      'japanese_name': japaneseName,
      'unit_price': unitPrice,
      'stock': stock,
      'unit_id': unitId,
      'unit': unit,
      'image_url': imageUrl,
      'product_images': productImages.isNotEmpty
          ? jsonEncode(productImages)
          : null,
      'description': description,
      'taxable': taxable,
      'chalan_number': chalanNumber,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final product = Product();
    product.id = map['id'] as int?;
    product.serverId = map['server_id'] as String;
    product.categoryId = map['category_id'] as String;
    product.name = map['name'] as String;
    product.japaneseName = map['japanese_name'] as String?;
    product.unitPrice = (map['unit_price'] as num).toDouble();
    product.stock = (map['stock'] as num?)?.toDouble() ?? 0;
    product.unitId = map['unit_id'] as String?;
    product.unit = map['unit'] as String?;
    product.imageUrl = map['image_url'] as String?;
    product.description = map['description'] as String?;
    product.taxable = (map['taxable'] as num?)?.toInt() ?? 0;
    product.chalanNumber = map['chalan_number'] as String?;
    final imagesRaw = map['product_images'] as String?;
    if (imagesRaw != null && imagesRaw.isNotEmpty) {
      product.productImages = (jsonDecode(imagesRaw) as List).cast<String>();
    }
    return product;
  }

  String? get firstImageUrl =>
      productImages.isNotEmpty ? productImages.first : imageUrl;
}
