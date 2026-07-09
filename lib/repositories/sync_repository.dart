import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_config.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../dto/sales_invoice_request.dart';
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

    await _db.update(
      'sync_queue',
      {'status': 'Pending'},
      where: "status = 'Syncing'",
    );

    final pending = await getPendingQueue();

    for (final entry in pending) {
      try {
        await _db.update(
          'sync_queue',
          {'status': 'Syncing'},
          where: 'id = ?',
          whereArgs: [entry.id],
        );

        if (entry.entityType == 'Estimate') {
          await _syncEstimateEntry(entry);
        } else if (entry.entityType == 'SalesReturn') {
          await _syncSalesReturnEntry(entry);
        } else {
          await _db.update(
            'sync_queue',
            {'status': 'Failed'},
            where: 'id = ?',
            whereArgs: [entry.id],
          );
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

  Future<void> _syncEstimateEntry(SyncQueue entry) async {
    final maps = await _db
        .query('estimate', where: 'id = ?', whereArgs: [entry.entityId]);
    if (maps.isEmpty) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return;
    }
    final estimate = Estimate.fromMap(maps.first);

    final deliveryMaps = await _db.query('delivery',
        where: 'id = ?', whereArgs: [estimate.deliveryId]);
    final customerId = deliveryMaps.isNotEmpty
        ? deliveryMaps.first['customer_id'] as String?
        : null;

    final itemMaps = await _db.query('estimate_item',
        where: 'estimate_id = ?', whereArgs: [estimate.id]);
    final items = itemMaps.map((m) => EstimateItem.fromMap(m)).toList();

    final productMaps = await _db.query('product');
    final productsMap = <String, Map<String, dynamic>>{
      for (final p in productMaps) (p['server_id'] as String): p,
    };

    final paymentModeMaps = await _db.query('payment_mode');
    final payModeName = estimate.paymentMode != null
        ? (paymentModeMaps.cast<Map<String, dynamic>?>().firstWhere(
              (m) => m?['server_id'] == estimate.paymentMode,
              orElse: () => null,
            )?['name'] as String? ?? 'Cash')
        : 'Cash';

    final now = estimate.createdDate;
    final transactionDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final totalQty = items.fold<double>(0, (sum, i) => sum + i.quantity);
    final invoiceGrossAmount = items.fold<double>(
        0, (sum, i) => sum + (i.unitPrice * i.quantity));
    final totalProductDiscount = items.fold<double>(
        0, (sum, i) => sum + i.discountAmount);
    final globalDiscount = estimate.discountAmount;
    final totalDiscount = totalProductDiscount + globalDiscount;
    final netAmount = invoiceGrossAmount - totalDiscount;

    final salesInvoiceItems = items.map((item) {
      final product = productsMap[item.productId];

      final taxableType = (product?['taxable'] as num?)?.toInt() ?? 0;
      final rate = item.unitPrice;
      final quantity = item.quantity;
      final discount = item.discountAmount;
      const taxPercent = 13.0;

      double rateIncTax;
      double grossAmount;
      double grossAmountIncTax;
      double taxableAmount;
      double nonTaxableAmount;
      double taxAmount;

      double rateExTax;
      if (taxableType == 0) {
        rateExTax = rate;
        rateIncTax = rate * (1 + taxPercent / 100);
        grossAmount = rateExTax * quantity;
        grossAmountIncTax = rateIncTax * quantity;
        taxableAmount = grossAmount;
        nonTaxableAmount = 0;
        taxAmount = grossAmountIncTax - grossAmount;
      } else if (taxableType == 1) {
        rateIncTax = rate;
        rateExTax = rate / (1 + taxPercent / 100);
        grossAmountIncTax = rateIncTax * quantity;
        grossAmount = rateExTax * quantity;
        taxableAmount = grossAmount;
        nonTaxableAmount = 0;
        taxAmount = grossAmountIncTax - grossAmount;
      } else {
        rateExTax = rate;
        rateIncTax = rate;
        grossAmount = rateExTax * quantity;
        grossAmountIncTax = grossAmount;
        taxableAmount = 0;
        nonTaxableAmount = grossAmount;
        taxAmount = 0;
      }

      final proportion = invoiceGrossAmount > 0
          ? (item.unitPrice * item.quantity) / invoiceGrossAmount
          : 1.0 / items.length;
      final itemGlobalDiscount = globalDiscount * proportion;
      final itemNetAfterAll = item.lineTotal - itemGlobalDiscount;

      return SalesInvoiceItemRequest(
        refNo: item.productId,
        chalanNumber: product?['chalan_number'] as String? ?? '',
        productId: item.productId,
        name: product?['name'] as String? ?? '',
        quantity: quantity,
        unitId: product?['unit_id'] as String? ?? '',
        unitName: product?['unit'] as String? ?? '',
        categoryId: product?['category_id'] as String? ?? '',
        rate: rateExTax,
        rateIncludingTax: rateIncTax,
        grossAmount: grossAmount,
        grossAmountIncludingTax: grossAmountIncTax,
        discount: discount,
        taxable: taxableAmount,
        nonTaxable: nonTaxableAmount,
        taxPercent: taxPercent,
        taxAmount: taxAmount,
        netAmount: itemNetAfterAll,
        salesInvoiceItemTax: [
          SalesInvoiceItemTaxRequest(
            taxableAmount: taxableAmount,
            taxAmount: taxAmount,
            netAmount: itemNetAfterAll,
          ),
        ],
      );
    }).toList();

    final totalTaxable = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.taxable);
    final totalNonTaxable = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.nonTaxable);
    final totalItemTax = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.taxAmount);

    final request = SalesInvoiceRequest(
      transactionDate: transactionDate,
      customerId: customerId,
      outletId: ApiConfig.emptyGuid,
      totalQuantity: totalQty,
      totalGrossAmount: invoiceGrossAmount,
      totalGrossAmountIncludingTax: invoiceGrossAmount + totalItemTax,
      totalDiscount: totalDiscount,
      totalDiscountIncludingTax: totalDiscount,
      totalTaxableAmount: totalTaxable,
      totalNonTaxableAmount: totalNonTaxable,
      totalTax: totalItemTax,
      totalNetAmount: netAmount + totalItemTax,
      totalPayableAmount: netAmount + totalItemTax,
      payMode: payModeName,
      tenderAmount: netAmount + totalItemTax,
      salesInvoiceTax: [
        SalesInvoiceTaxRequest(taxAmount: totalItemTax),
      ],
      salesInvoiceItem: salesInvoiceItems,
      salesInvoicePayment: [
        SalesInvoicePaymentRequest(
          payMode: payModeName,
          paymentId: estimate.paymentMode ?? ApiConfig.emptyGuid,
          amount: estimate.paidAmount > 0 ? estimate.paidAmount : netAmount + totalItemTax,
        ),
      ],
      currencyId: ApiConfig.defaultCurrencyId,
    );

    final response = await _apiService.createSalesInvoice(request);

    if (response.success) {
      await _db.update(
        'estimate',
        {'server_id': response.invoiceId, 'is_synced': 1},
        where: 'id = ?',
        whereArgs: [estimate.id],
      );
      await _db.update(
        'sync_queue',
        {'status': 'Synced'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } else {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }

  Future<void> _syncSalesReturnEntry(SyncQueue entry) async {
    final maps = await _db
        .query('sales_return', where: 'id = ?', whereArgs: [entry.entityId]);
    if (maps.isEmpty) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return;
    }
    final sr = SalesReturn.fromMap(maps.first);

    final itemMaps = await _db.query('sales_return_item',
        where: 'sales_return_id = ?', whereArgs: [sr.id]);
    sr.items = itemMaps.map((m) => SalesReturnItem.fromMap(m)).toList();

    final payload = {
      ...sr.toMap(),
      'items': sr.items.map((item) => item.toMap()).toList(),
    };
    final response = await _apiService.createSalesReturn(payload);

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
    } else {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }
}

