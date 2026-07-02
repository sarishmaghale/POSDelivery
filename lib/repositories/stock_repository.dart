import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/driver_stock.dart';
import '../models/product.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class StockRepository {
  final ApiService _apiService;
  final Database _db;

  StockRepository({
    required ApiService apiService,
    required Database db,
  })  : _apiService = apiService,
        _db = db;

  Future<List<DriverStock>> refreshStock() async {
    final stockList = await fetchStockFromApi();
    if (stockList.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('driver_stock');
        for (final s in stockList) {
          txn.insert('driver_stock', s.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
          
          await txn.update(
            'product',
            {'stock': s.remainingQuantity},
            where: 'server_id = ?',
            whereArgs: [s.productId],
          );
        }
      });
    }
    return stockList;
  }

  Future<List<DriverStock>> fetchStockFromApi() async {
    final data = await _apiService.fetchStock();
    return data.map((json) => DriverStock()
      ..productId = json['productId'] as String
      ..assignedQuantity = (json['assignedQuantity'] as num).toDouble()
      ..deliveredQuantity = (json['deliveredQuantity'] as num?)?.toDouble() ?? 0
    ).toList();
  }

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

    for (final stock in stockList) {
      final productMaps = await _db.query('product',
          where: 'server_id = ?', whereArgs: [stock.productId]);
      if (productMaps.isNotEmpty) {
        final product = Product.fromMap(productMaps.first);
        result.add({
          'product': product,
          'stock': stock,
        });
      }
    }
    return result;
  }
}
