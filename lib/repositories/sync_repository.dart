import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../dto/delivery_request.dart';
import '../dto/estimate_request.dart';
import '../models/delivery.dart';
import '../models/estimate.dart';
import '../models/sales_return.dart';
import '../models/sync_queue.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
    networkChecker: ref.read(networkCheckerProvider),
  );
});

class SyncRepository {
  final ApiService _apiService;
  final Database _db;
  final NetworkChecker _networkChecker;

  SyncRepository({
    required ApiService apiService,
    required Database db,
    required NetworkChecker networkChecker,
  })  : _apiService = apiService,
        _db = db,
        _networkChecker = networkChecker;

  Future<List<SyncQueue>> getPendingQueue() async {
    final maps = await _db.rawQuery(
      "SELECT * FROM sync_queue WHERE status != 'Synced' ORDER BY created_date ASC",
    );
    return maps.map((m) => SyncQueue.fromMap(m)).toList();
  }

  Future<int> getPendingCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFailedCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Failed'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncedCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Synced'",
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

  Future<bool> syncAll() async {
    final isOnline = await _networkChecker.isConnected;
    if (!isOnline) return false;

    final pending = await getPendingQueue();

    for (final entry in pending) {
      try {
        await _db.update(
          'sync_queue',
          {'status': 'Syncing'},
          where: 'id = ?',
          whereArgs: [entry.id],
        );

        if (entry.entityType == 'Delivery') {
          await _syncDeliveryEntry(entry);
        } else if (entry.entityType == 'Estimate') {
          await _syncEstimateEntry(entry);
        } else if (entry.entityType == 'SalesReturn') {
          await _syncSalesReturnEntry(entry);
        }
      } catch (_) {
        await _db.update(
          'sync_queue',
          {'status': 'Failed'},
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      }
    }

    return true;
  }

  Future<void> _syncDeliveryEntry(SyncQueue entry) async {
    final maps = await _db
        .query('delivery', where: 'id = ?', whereArgs: [entry.entityId]);
    if (maps.isEmpty) return;
    final delivery = Delivery.fromMap(maps.first);

    final itemMaps = await _db.query('delivery_item',
        where: 'delivery_id = ?', whereArgs: [delivery.id]);
    final items = itemMaps.map((m) => DeliveryItem.fromMap(m)).toList();

    final request = DeliveryRequest(
      customerId: delivery.customerId,
      items: items
          .map((e) => DeliveryItemRequest(
                productId: e.productId,
                quantity: e.quantity,
              ))
          .toList(),
    );

    final response = await _apiService.createDelivery(request);

    if (response.success) {
      await _db.update(
        'delivery',
        {'server_id': response.deliveryId, 'is_synced': 1},
        where: 'id = ?',
        whereArgs: [delivery.id],
      );
      await _db.update(
        'sync_queue',
        {'status': 'Synced'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }

  Future<void> _syncEstimateEntry(SyncQueue entry) async {
    final maps = await _db
        .query('estimate', where: 'id = ?', whereArgs: [entry.entityId]);
    if (maps.isEmpty) return;
    final estimate = Estimate.fromMap(maps.first);

    final itemMaps = await _db.query('estimate_item',
        where: 'estimate_id = ?', whereArgs: [estimate.id]);
    final items = itemMaps.map((m) => EstimateItem.fromMap(m)).toList();

    final request = EstimateRequest(
      deliveryId: estimate.deliveryId.toString(),
      items: items
          .map((e) => EstimateItemRequest(
                productId: e.productId,
                quantity: e.quantity,
                unitPrice: e.unitPrice,
                lineTotal: e.lineTotal,
              ))
          .toList(),
      estimatedTotal: estimate.estimatedTotal,
      paymentMode: estimate.paymentMode,
      paidAmount: estimate.paidAmount,
      remarks: estimate.remarks,
    );

    final response = await _apiService.createEstimate(request);

    if (response.success) {
      await _db.update(
        'estimate',
        {'server_id': response.estimateId, 'is_synced': 1},
        where: 'id = ?',
        whereArgs: [estimate.id],
      );
      await _db.update(
        'sync_queue',
        {'status': 'Synced'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }

  Future<void> _syncSalesReturnEntry(SyncQueue entry) async {
    final maps = await _db
        .query('sales_return', where: 'id = ?', whereArgs: [entry.entityId]);
    if (maps.isEmpty) return;
    final sr = SalesReturn.fromMap(maps.first);

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
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }
}

