import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../models/sales_return.dart';
import '../models/sync_queue.dart';

final salesReturnRepositoryProvider = Provider<SalesReturnRepository>((ref) {
  return SalesReturnRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
    networkChecker: ref.read(networkCheckerProvider),
  );
});

class SalesReturnRepository {
  final ApiService _apiService;
  final Database _db;
  final NetworkChecker _networkChecker;

  SalesReturnRepository({
    required ApiService apiService,
    required Database db,
    required NetworkChecker networkChecker,
  })  : _apiService = apiService,
        _db = db,
        _networkChecker = networkChecker;

  Future<SalesReturn> saveSalesReturn({
    required String customerId,
    required String productId,
    required double quantity,
    String? reason,
    String? remarks,
  }) async {
    final sr = SalesReturn()
      ..customerId = customerId
      ..productId = productId
      ..quantity = quantity
      ..reason = reason
      ..remarks = remarks
      ..createdDate = DateTime.now()
      ..isSynced = false;

    final id = await _db.insert('sales_return', sr.toMap());
    sr.id = id;

    final syncEntry = SyncQueue()
      ..entityType = 'SalesReturn'
      ..entityId = id
      ..status = 'Pending'
      ..createdDate = DateTime.now();
    await _db.insert('sync_queue', syncEntry.toMap());

    final isOnline = await _networkChecker.isConnected;
    if (isOnline) {
      await _syncSalesReturn(sr);
    }

    return sr;
  }

  Future<void> _syncSalesReturn(SalesReturn sr) async {
    await _db.update(
      'sync_queue',
      {'status': 'Syncing'},
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['SalesReturn', sr.id],
    );

    try {
      final response = await _apiService.createSalesReturn(sr.toMap());

      if (response) {
        await _db.update(
          'sales_return',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [sr.id],
        );
        await _db.update(
          'sync_queue',
          {'status': 'Synced'},
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['SalesReturn', sr.id],
        );
      }
    } catch (_) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['SalesReturn', sr.id],
      );
    }
  }

  Future<List<SalesReturn>> getReturnsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await _db.query('sales_return',
        where: 'created_date >= ? AND created_date < ?',
        whereArgs: [
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String()
        ],
        orderBy: 'created_date DESC');
    return maps.map((m) => SalesReturn.fromMap(m)).toList();
  }

  Future<List<SalesReturn>> getPendingReturns() async {
    final maps = await _db
        .query('sales_return', where: 'is_synced = ?', whereArgs: [0]);
    return maps.map((m) => SalesReturn.fromMap(m)).toList();
  }

  Future<int> getTodaysReturnsCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM sales_return WHERE created_date >= ? AND created_date < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
