import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../dto/delivery_request.dart';
import '../models/delivery.dart';
import '../models/sync_queue.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
    networkChecker: ref.read(networkCheckerProvider),
  );
});

class DeliveryRepository {
  final ApiService _apiService;
  final Database _db;
  final NetworkChecker _networkChecker;

  DeliveryRepository({
    required ApiService apiService,
    required Database db,
    required NetworkChecker networkChecker,
  })  : _apiService = apiService,
        _db = db,
        _networkChecker = networkChecker;

  Future<Delivery> updateDelivery(
    int deliveryId, {
    required String customerId,
    required List<DeliveryItem> items,
    String? paymentMode,
  }) async {
    final delivery = Delivery()
      ..id = deliveryId
      ..customerId = customerId
      ..createdDate = DateTime.now()
      ..paymentMode = paymentMode
      ..isSynced = false;

    await _db.update(
      'delivery',
      delivery.toMap(),
      where: 'id = ?',
      whereArgs: [deliveryId],
    );

    await _db.delete('delivery_item',
        where: 'delivery_id = ?', whereArgs: [deliveryId]);

    for (final item in items) {
      item.deliveryId = deliveryId;
      await _db.insert('delivery_item', item.toMap());
    }

    final existingSync = await _db.query('sync_queue',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Delivery', deliveryId]);
    if (existingSync.isEmpty) {
      final syncEntry = SyncQueue()
        ..entityType = 'Delivery'
        ..entityId = deliveryId
        ..status = 'Pending'
        ..createdDate = DateTime.now();
      await _db.insert('sync_queue', syncEntry.toMap());
    } else {
      await _db.update(
        'sync_queue',
        {'status': 'Pending'},
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Delivery', deliveryId],
      );
    }

    final isOnline = await _networkChecker.isConnected;
    if (isOnline) {
      await _syncDelivery(delivery);
    }

    return delivery;
  }

  Future<Delivery> saveDelivery({
    required String customerId,
    required List<DeliveryItem> items,
    String? paymentMode,
  }) async {
    final delivery = Delivery()
      ..customerId = customerId
      ..createdDate = DateTime.now()
      ..paymentMode = paymentMode
      ..isSynced = false;

    final id = await _db.insert('delivery', delivery.toMap());
    delivery.id = id;

    for (final item in items) {
      item.deliveryId = id;
      await _db.insert('delivery_item', item.toMap());
    }

    final syncEntry = SyncQueue()
      ..entityType = 'Delivery'
      ..entityId = id
      ..status = 'Pending'
      ..createdDate = DateTime.now();
    await _db.insert('sync_queue', syncEntry.toMap());

    final isOnline = await _networkChecker.isConnected;
    if (isOnline) {
      await _syncDelivery(delivery);
    }

    return delivery;
  }

  Future<void> _syncDelivery(Delivery delivery) async {
    await _db.update(
      'sync_queue',
      {'status': 'Syncing'},
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['Delivery', delivery.id],
    );

    try {
      final itemMaps = await _db.query('delivery_item',
          where: 'delivery_id = ?', whereArgs: [delivery.id]);
      final items = itemMaps.map((m) => DeliveryItem.fromMap(m)).toList();

      final request = DeliveryRequest(
        customerId: delivery.customerId,
        paymentMode: delivery.paymentMode,
        items: items
            .map((e) => DeliveryItemRequest(
                  productId: e.productId,
                  quantity: e.quantity,
                  unitPrice: e.unitPrice,
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
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['Delivery', delivery.id],
        );
      }
    } catch (_) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Delivery', delivery.id],
      );
    }
  }

  Future<List<Delivery>> getDeliveriesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await _db.query('delivery',
        where: 'created_date >= ? AND created_date < ?',
        whereArgs: [
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String()
        ],
        orderBy: 'created_date DESC');
    return maps.map((m) => Delivery.fromMap(m)).toList();
  }

  Future<List<Delivery>> getPendingDeliveries() async {
    final maps = await _db
        .query('delivery', where: 'is_synced = ?', whereArgs: [0]);
    return maps.map((m) => Delivery.fromMap(m)).toList();
  }

  Future<Delivery?> getDeliveryById(int id) async {
    final maps =
        await _db.query('delivery', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Delivery.fromMap(maps.first);
  }

  Future<List<DeliveryItem>> getDeliveryItems(int deliveryId) async {
    final maps = await _db.query('delivery_item',
        where: 'delivery_id = ?', whereArgs: [deliveryId]);
    return maps.map((m) => DeliveryItem.fromMap(m)).toList();
  }
}

