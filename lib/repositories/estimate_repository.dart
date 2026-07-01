import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../dto/estimate_request.dart';
import '../models/estimate.dart';
import '../models/sync_queue.dart';

final estimateRepositoryProvider = Provider<EstimateRepository>((ref) {
  return EstimateRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
    networkChecker: ref.read(networkCheckerProvider),
  );
});

class EstimateRepository {
  final ApiService _apiService;
  final Database _db;
  final NetworkChecker _networkChecker;

  EstimateRepository({
    required ApiService apiService,
    required Database db,
    required NetworkChecker networkChecker,
  })  : _apiService = apiService,
        _db = db,
        _networkChecker = networkChecker;

  Future<Estimate> saveEstimate({
    required int deliveryId,
    required List<EstimateItem> items,
    String? paymentMode,
    double? paidAmount,
    String? remarks,
    String? discountType,
    double? discountValue,
    double? discountAmount,
  }) async {
    final grossTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final netTotal = grossTotal - (discountAmount ?? 0);

    final estimate = Estimate()
      ..deliveryId = deliveryId
      ..grossTotal = grossTotal
      ..estimatedTotal = netTotal
      ..discountType = discountType
      ..discountValue = discountValue ?? 0
      ..discountAmount = discountAmount ?? 0
      ..paymentMode = paymentMode
      ..paidAmount = paidAmount ?? 0
      ..remarks = remarks
      ..createdDate = DateTime.now()
      ..isSynced = false;

    final id = await _db.insert('estimate', estimate.toMap());
    estimate.id = id;

    for (final item in items) {
      item.estimateId = id;
      await _db.insert('estimate_item', item.toMap());
    }

    final syncEntry = SyncQueue()
      ..entityType = 'Estimate'
      ..entityId = id
      ..status = 'Pending'
      ..createdDate = DateTime.now();
    await _db.insert('sync_queue', syncEntry.toMap());

    final isOnline = await _networkChecker.isConnected;
    if (isOnline) {
      await _syncEstimate(estimate);
    }

    return estimate;
  }

  Future<void> _syncEstimate(Estimate estimate) async {
    await _db.update(
      'sync_queue',
      {'status': 'Syncing'},
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['Estimate', estimate.id],
    );

    try {
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
        discountType: estimate.discountType,
        discountValue: estimate.discountValue,
        discountAmount: estimate.discountAmount,
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
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['Estimate', estimate.id],
        );
      }
    } catch (_) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Estimate', estimate.id],
      );
    }
  }

  Future<List<Estimate>> getEstimatesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await _db.query('estimate',
        where: 'created_date >= ? AND created_date < ?',
        whereArgs: [
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String()
        ],
        orderBy: 'created_date DESC');
    return maps.map((m) => Estimate.fromMap(m)).toList();
  }

  Future<List<Estimate>> getEstimatesByDelivery(int deliveryId) async {
    final maps = await _db.query('estimate',
        where: 'delivery_id = ?', whereArgs: [deliveryId]);
    return maps.map((m) => Estimate.fromMap(m)).toList();
  }
}

