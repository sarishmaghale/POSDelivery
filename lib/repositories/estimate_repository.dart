import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../dto/sales_invoice_request.dart';
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
  }) : _apiService = apiService,
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
    SalesInvoiceRequest? salesInvoiceRequest,
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

    final id = await _db.transaction((txn) async {
      final estimateId = await txn.insert('estimate', estimate.toMap());
      for (final item in items) {
        item.estimateId = estimateId;
        await txn.insert('estimate_item', item.toMap());
      }
      final syncEntry = SyncQueue()
        ..entityType = 'Delivery'
        ..entityId = deliveryId
        ..status = 'Pending'
        ..createdDate = DateTime.now();
      await txn.insert('sync_queue', syncEntry.toMap());
      return estimateId;
    });
    estimate.id = id;

    final isOnline = await _networkChecker.isConnected;
    if (isOnline && salesInvoiceRequest != null) {
      await _syncSalesInvoice(salesInvoiceRequest, id, deliveryId);
    }

    return estimate;
  }

  Future<void> _syncSalesInvoice(
    SalesInvoiceRequest request,
    int estimateId,
    int deliveryId,
  ) async {
    await _db.update(
      'sync_queue',
      {'status': 'Syncing'},
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['Delivery', deliveryId],
    );

    try {
      final response = await _apiService.createSalesInvoice(request);
      if (response.success) {
        await _db.update(
          'estimate',
          {'server_id': response.invoiceId, 'is_synced': 1},
          where: 'id = ?',
          whereArgs: [estimateId],
        );
        await _db.update(
          'sync_queue',
          {'status': 'Synced'},
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['Delivery', deliveryId],
        );
        await _db.update(
          'delivery',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [deliveryId],
        );
      } else {
        await _db.update(
          'sync_queue',
          {'status': 'Failed'},
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['Delivery', deliveryId],
        );
      }
    } catch (_) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Delivery', deliveryId],
      );
    }
  }

  Future<List<Estimate>> getEstimatesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await _db.query(
      'estimate',
      where: 'created_date >= ? AND created_date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'created_date DESC',
    );
    return maps.map((m) => Estimate.fromMap(m)).toList();
  }

  Future<List<Estimate>> getEstimatesByDelivery(int deliveryId) async {
    final maps = await _db.query(
      'estimate',
      where: 'delivery_id = ?',
      whereArgs: [deliveryId],
    );
    return maps.map((m) => Estimate.fromMap(m)).toList();
  }

  Future<List<EstimateItem>> getEstimateItems(int estimateId) async {
    final maps = await _db.query(
      'estimate_item',
      where: 'estimate_id = ?',
      whereArgs: [estimateId],
    );
    return maps.map((m) => EstimateItem.fromMap(m)).toList();
  }
}
