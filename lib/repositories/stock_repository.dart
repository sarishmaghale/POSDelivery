import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../models/driver_stock.dart';
import '../models/product.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(
    db: ref.read(databaseServiceProvider).db,
  );
});

class StockRepository {
  final Database _db;

  StockRepository({
    required this._db,
  });

  Future<void> saveStock(List<DriverStock> stockList) async {
    final batch = _db.batch();
    for (final stock in stockList) {
      batch.insert('driver_stock', stock.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<DriverStock>> getAllStock() async {
    final maps = await _db.query('driver_stock');
    return maps.map((m) => DriverStock.fromMap(m)).toList();
  }

  Future<DriverStock?> getStockForProduct(String productId) async {
    final maps = await _db.query('driver_stock',
        where: 'product_id = ?', whereArgs: [productId]);
    if (maps.isEmpty) return null;
    return DriverStock.fromMap(maps.first);
  }

  Future<double> getRemainingQuantity(String productId) async {
    final stock = await getStockForProduct(productId);
    if (stock == null) return 0;
    return stock.remainingQuantity;
  }

  Future<bool> validateQuantity(String productId, double requestedQty) async {
    final remaining = await getRemainingQuantity(productId);
    return requestedQty <= remaining;
  }

  Future<void> deductStock(String productId, double quantity) async {
    final stock = await getStockForProduct(productId);
    if (stock == null) return;

    final newDelivered = stock.deliveredQuantity + quantity;
    await _db.update(
      'driver_stock',
      {'delivered_quantity': newDelivered},
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> deductStockForDelivery(List<Map<String, double>> items) async {
    for (final item in items) {
      for (final entry in item.entries) {
        await deductStock(entry.key, entry.value);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAssignedStockWithProducts() async {
    final result = <Map<String, dynamic>>[];
    final stockList = await getAllStock();

    if (stockList.isEmpty) return result;

    final productIds = stockList.map((s) => s.productId).toList();
    final placeholders = List.generate(productIds.length, (_) => '?').join(',');
    final productMaps = await _db.query('product',
        where: 'server_id IN ($placeholders)', whereArgs: productIds);
    final productMap = {
      for (final m in productMaps) m['server_id'] as String: Product.fromMap(m)
    };

    for (final stock in stockList) {
      final product = productMap[stock.productId];
      if (product != null) {
        result.add({
          'product': product,
          'stock': stock,
        });
      }
    }
    return result;
  }
}
