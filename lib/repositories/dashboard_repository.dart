import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../dto/dashboard_response.dart';
import '../models/category.dart';
import '../models/driver.dart';
import '../models/driver_stock.dart';
import '../models/product.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class DashboardRepository {
  final ApiService _apiService;
  final Database _db;

  DashboardRepository({
    required ApiService apiService,
    required Database db,
  })  : _apiService = apiService,
        _db = db;

  Future<DashboardResponse> fetchDashboard() {
    return _apiService.fetchDashboard();
  }

  Future<Driver?> getDriver() async {
    final maps = await _db.query('driver', limit: 1);
    if (maps.isEmpty) return null;
    return Driver.fromMap(maps.first);
  }

  Future<int> getTodaysDeliveries() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM delivery WHERE created_date >= ? AND created_date < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getEstimatedBillsCreated() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM estimate WHERE created_date >= ? AND created_date < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingSyncCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<DateTime?> getLastSyncTime() async {
    final maps = await _db.rawQuery(
      "SELECT * FROM sync_queue WHERE status = 'Synced' ORDER BY created_date DESC LIMIT 1",
    );
    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['created_date'] as String);
  }

  Future<void> saveDriver(Driver driver) async {
    await _db.insert('driver', driver.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveCategories(List<Category> categories) async {
    final batch = _db.batch();
    for (final cat in categories) {
      batch.insert('category', cat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveProducts(List<Product> products) async {
    final batch = _db.batch();
    for (final prod in products) {
      batch.insert('product', prod.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> getTodaysSalesReturns() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM sales_return WHERE created_date >= ? AND created_date < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAssignedCustomersCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM customer');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAssignedProductsCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM driver_stock');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRemainingAssignedStock() async {
    final stockMaps = await _db.query('driver_stock');
    final result = <Map<String, dynamic>>[];

    for (final stockMap in stockMaps) {
      final stock = DriverStock.fromMap(stockMap);
      final productMaps = await _db.query('product',
          where: 'server_id = ?', whereArgs: [stock.productId]);
      if (productMaps.isNotEmpty) {
        final product = Product.fromMap(productMaps.first);
        result.add({
          'product': product,
          'assigned': stock.assignedQuantity,
          'delivered': stock.deliveredQuantity,
          'remaining': stock.remainingQuantity,
        });
      }
    }
    return result;
  }

  Future<void> saveDriverStock(List<DriverStock> stockList) async {
    final batch = _db.batch();
    for (final stock in stockList) {
      batch.insert('driver_stock', stock.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}

