import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_config.dart';
import '../../../core/services/image_prefetch_service.dart';
import '../../../models/sync_queue.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/payment_mode_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/sync_repository.dart';

class SyncStatus {
  final String label;
  final bool? success; // null = pending, true = ok, false = failed
  final String? error;

  const SyncStatus({required this.label, this.success, this.error});
}

class SyncState {
  final List<SyncQueue> pendingQueue;
  final int pendingCount;
  final int failedCount;
  final int syncedCount;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final bool syncResult;
  final String? errorMessage;
  final Map<String, SyncStatus> incomingStatus;

  SyncState({
    this.pendingQueue = const [],
    this.pendingCount = 0,
    this.failedCount = 0,
    this.syncedCount = 0,
    this.lastSyncTime,
    this.isSyncing = false,
    this.syncResult = false,
    this.errorMessage,
    this.incomingStatus = const {},
  });
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(
    syncRepo: ref.read(syncRepositoryProvider),
    categoryRepo: ref.read(categoryRepositoryProvider),
    productRepo: ref.read(productRepositoryProvider),
    customerRepo: ref.read(customerRepositoryProvider),
    paymentModeRepo: ref.read(paymentModeRepositoryProvider),
  );
});

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncRepository _syncRepo;
  final CategoryRepository _categoryRepo;
  final ProductRepository _productRepo;
  final CustomerRepository _customerRepo;
  final PaymentModeRepository _paymentModeRepo;

  SyncNotifier({
    required this._syncRepo,
    required CategoryRepository categoryRepo,
    required this._productRepo,
    required this._customerRepo,
    required this._paymentModeRepo,
  })  : _categoryRepo = categoryRepo,
        super(SyncState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = SyncState(
      pendingQueue: await _syncRepo.getPendingQueue(),
      pendingCount: await _syncRepo.getPendingCount(),
      failedCount: await _syncRepo.getFailedCount(),
      syncedCount: await _syncRepo.getSyncedCount(),
      lastSyncTime: await _syncRepo.getLastSyncTime(),
    );
  }

  Future<bool> syncAll() async {
    state = SyncState(
      pendingQueue: state.pendingQueue,
      pendingCount: state.pendingCount,
      failedCount: state.failedCount,
      syncedCount: state.syncedCount,
      lastSyncTime: state.lastSyncTime,
      isSyncing: true,
incomingStatus: {
        'categories': const SyncStatus(label: 'Categories', success: null),
        'assignedProducts': const SyncStatus(label: 'Assigned Products', success: null),
        'allProducts': const SyncStatus(label: 'All Products', success: null),
        'customers': const SyncStatus(label: 'Customers', success: null),
        'paymentModes': const SyncStatus(label: 'Payment Modes', success: null),
      },
    );

    final results = await _syncFromServer();
    final allOk = results.entries.where((e) => e.key.endsWith('_error')).isEmpty &&
        results['categories'] == true &&
        results['assignedProducts'] == true &&
        results['allProducts'] == true &&
        results['customers'] == true &&
        results['paymentModes'] == true;

    if (!allOk) {
      state = SyncState(
incomingStatus: {
          'categories': SyncStatus(label: 'Categories', success: results['categories'], error: results['categories_error']),
          'assignedProducts': SyncStatus(label: 'Assigned Products', success: results['assignedProducts'], error: results['assignedProducts_error']),
          'allProducts': SyncStatus(label: 'All Products', success: results['allProducts'], error: results['allProducts_error']),
          'customers': SyncStatus(label: 'Customers', success: results['customers'], error: results['customers_error']),
          'paymentModes': SyncStatus(label: 'Payment Modes', success: results['paymentModes'], error: results['paymentModes_error']),
        },
        isSyncing: true,
      );
    }

    try {
      await _syncRepo.syncAll();
    } catch (_) {}

    await refresh();

    final queuePending = state.pendingCount;
    final queueFailed = state.failedCount;
    final queueSyncOk = queuePending == 0 && queueFailed == 0;

    state = SyncState(
      pendingQueue: state.pendingQueue,
      pendingCount: state.pendingCount,
      failedCount: state.failedCount,
      syncedCount: state.syncedCount,
      lastSyncTime: state.lastSyncTime,
      isSyncing: false,
      syncResult: allOk && queueSyncOk,
      errorMessage: allOk
          ? (queueSyncOk ? null : 'Some bills failed to push to server.')
          : 'Some data failed to sync from server. Local data preserved.',
      incomingStatus: {
        'categories': SyncStatus(label: 'Categories', success: results['categories'], error: results['categories_error']),
        'assignedProducts': SyncStatus(label: 'Assigned Products', success: results['assignedProducts'], error: results['assignedProducts_error']),
        'allProducts': SyncStatus(label: 'All Products', success: results['allProducts'], error: results['allProducts_error']),
        'customers': SyncStatus(label: 'Customers', success: results['customers'], error: results['customers_error']),
        'paymentModes': SyncStatus(label: 'Payment Modes', success: results['paymentModes'], error: results['paymentModes_error']),
      },
    );

    return allOk;
  }

  Future<Map<String, dynamic>> _syncFromServer() async {
    final results = <String, dynamic>{};

    final now = DateTime.now();
    final transactionDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final categories = await _categoryRepo.refreshCategories(
        customerId: ApiConfig.defaultCustomerId,
        transactionDate: transactionDate,
      );
      results['categories'] = true;
      final catUrls = categories
          .where((c) => c.firstImageUrl != null && c.firstImageUrl!.isNotEmpty)
          .map((c) => c.firstImageUrl!)
          .toList();
      if (catUrls.isNotEmpty) {
        ImagePrefetchService().prefetchImages(catUrls);
      }
    } catch (e) {
      results['categories'] = false;
      results['categories_error'] = e.toString();
    }

    try {
      final products = await _productRepo.refreshProducts(
        customerId: ApiConfig.defaultCustomerId,
        transactionDate: transactionDate,
      );
      results['assignedProducts'] = true;
      final prodUrls = products
          .where((p) => p.firstImageUrl != null && p.firstImageUrl!.isNotEmpty)
          .map((p) => p.firstImageUrl!)
          .toList();
      if (prodUrls.isNotEmpty) {
        ImagePrefetchService().prefetchImages(prodUrls);
      }
    } catch (e) {
      print('[Sync] Assigned Products error: $e');
      results['assignedProducts'] = false;
      results['assignedProducts_error'] = e.toString();
    }

    try {
      await _productRepo.refreshAllProducts();
      results['allProducts'] = true;
    } catch (e) {
      print('[Sync] All Products error: $e');
      results['allProducts'] = false;
      results['allProducts_error'] = e.toString();
    }

    try {
      await _customerRepo.refreshCustomers();
      results['customers'] = true;
    } catch (e) {
      results['customers'] = false;
      results['customers_error'] = e.toString();
    }

    try {
      await _paymentModeRepo.refreshPaymentModes();
      results['paymentModes'] = true;
    } catch (e) {
      results['paymentModes'] = false;
      results['paymentModes_error'] = e.toString();
    }

    return results;
  }
}
