
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class ProductRepository {
  final ApiService _apiService;
  final Database _db;

  ProductRepository({required ApiService apiService, required Database db})
    : _apiService = apiService,
      _db = db;

  Future<List<Product>> getProducts() async {
    final cached = await _db.query('product');
    if (cached.isNotEmpty) {
      return cached.map((map) => Product.fromMap(map)).toList();
    }
    return _fetchAndCacheProducts();
  }

  Future<List<Product>> refreshProducts() async {
    return _fetchAndCacheProducts();
  }

  Future<List<Product>> getCachedProducts() async {
    final maps = await _db.query('product');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> refreshAllProducts() async {
    final data = await _apiService.fetchAllProducts();
    final products = data.map((json) {
      final p = Product();
      p.serverId = json['ProductId'] as String;
      p.categoryId = json['CategoryId'] as String;
      p.name = json['Name'] as String;
      p.code = json['Code'] as String?;
      p.japaneseName = json['JapneseName'] as String?;
      p.imageUrl = json['ImagePath'] as String?;
      p.unitId = json['BaseUnitId'] as String?;
      p.unit = json['BaseUnitName'] as String?;
      p.unitPrice = (json['Rate'] as num?)?.toDouble() ?? 0;
      return p;
    }).toList();

    if (products.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('all_product');
        for (final p in products) {
          await txn.insert('all_product', {
            'server_id': p.serverId,
            'code': p.code,
            'category_id': p.categoryId,
            'name': p.name,
            'japanese_name': p.japaneseName,
            'unit_id': p.unitId,
            'unit': p.unit,
            'unit_price':p.unitPrice,
            'image_url': p.imageUrl,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }

    return products;
  }

  Future<List<Product>> getCachedAllProducts() async {
    final maps = await _db.query('all_product');
    return maps.map((map) {
      final p = Product();
      p.serverId = map['server_id'] as String;
      p.code = map['code'] as String?;
      p.categoryId = map['category_id'] as String;
      p.name = map['name'] as String;
      p.japaneseName = map['japanese_name'] as String?;
      p.unitId = map['unit_id'] as String?;
      p.unit = map['unit'] as String?;
      p.imageUrl = map['image_url'] as String?;
      p.unitPrice = map['unit_price'] as double;
      return p;
    }).toList();
  }

  Future<List<Product>> _fetchAndCacheProducts() async {
    final data = await _apiService.fetchProducts();
    final products = data.map((json) {
      final p = Product();
      p.serverId = json['Id'] as String? ?? json['id'] as String;
      p.categoryId =
          json['CategoryId'] as String? ?? json['categoryId'] as String;
      p.name = json['Name'] as String? ?? json['name'] as String;
      p.japaneseName = json['JapaneseName'] as String?;
      p.unitPrice =
          (json['Rate'] as num?)?.toDouble() ??
          (json['unitPrice'] as num).toDouble();
      p.stock = (json['Stock'] as num?)?.toDouble() ?? 20;
      if (p.stock <= 0) p.stock = 20;

      p.unitId = json['UnitId'] as String?;
      p.unit = json['UnitName'] as String? ?? json['unit'] as String?;
      p.description =
          json['Description'] as String? ?? json['description'] as String?;

      final rawImages =
          json['ProductImage'] as List? ?? json['productImages'] as List?;
      if (rawImages != null) {
        p.productImages = rawImages.map((e) {
          if (e is String) return e;
          if (e is Map)
            return (e['ImagePath'] ?? e['imagePath'] ?? e['url'] ?? '')
                as String;
          return e.toString();
        }).toList();
        if (p.productImages.isNotEmpty && p.imageUrl == null) {
          p.imageUrl ??= p.productImages.first;
        }
      }

      final rawImageUrl = json['imageUrl'] as String?;
      if (rawImageUrl != null) {
        p.imageUrl = rawImageUrl;
      }

      return p;
    }).toList();

    if (products.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('product');
        for (final p in products) {
          txn.insert(
            'product',
            p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }

    return products;
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final maps = await _db.query(
      'product',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> restoreStock(String productId, double quantity) async {
    final maps = await _db.query(
      'product',
      where: 'server_id = ?',
      whereArgs: [productId],
    );
    if (maps.isEmpty) return;
    final currentStock = (maps.first['stock'] as num?)?.toDouble() ?? 0;
    final newStock = currentStock + quantity;
    await _db.update(
      'product',
      {'stock': newStock},
      where: 'server_id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> deductStock(String productId, double quantity) async {
    final maps = await _db.query(
      'product',
      where: 'server_id = ?',
      whereArgs: [productId],
    );
    if (maps.isEmpty) return;
    final currentStock = (maps.first['stock'] as num?)?.toDouble() ?? 0;
    final newStock = currentStock - quantity;
    final effectiveStock = (newStock).clamp(0, double.infinity);
    await _db.update(
      'product',
      {'stock': effectiveStock},
      where: 'server_id = ?',
      whereArgs: [productId],
    );
  }
}
