import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_checker.dart';
import '../../../core/network/providers.dart';
import '../../../models/sync_queue.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/stock_repository.dart';
import '../../../repositories/sync_repository.dart';

class SyncStatus {
  final String label;
  final bool? success; // null = pending, true = ok, false = failed

  const SyncStatus({required this.label, this.success});
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
    stockRepo: ref.read(stockRepositoryProvider),
    networkChecker: ref.read(networkCheckerProvider),
  );
});

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncRepository _syncRepo;
  final CategoryRepository _categoryRepo;
  final ProductRepository _productRepo;
  final CustomerRepository _customerRepo;
  final StockRepository _stockRepo;
  final NetworkChecker _networkChecker;

  SyncNotifier({
    required SyncRepository syncRepo,
    required CategoryRepository categoryRepo,
    required ProductRepository productRepo,
    required CustomerRepository customerRepo,
    required StockRepository stockRepo,
    required NetworkChecker networkChecker,
  })  : _syncRepo = syncRepo,
        _categoryRepo = categoryRepo,
        _productRepo = productRepo,
        _customerRepo = customerRepo,
        _stockRepo = stockRepo,
        _networkChecker = networkChecker,
        super(SyncState()) {
    refresh();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _networkChecker.onConnectivityChanged.listen((isConnected) {
      if (isConnected && state.pendingCount > 0) {
        syncAll();
      }
    });
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
        'products': const SyncStatus(label: 'Products', success: null),
        'customers': const SyncStatus(label: 'Customers', success: null),
        'stock': const SyncStatus(label: 'Stock', success: null),
      },
    );

    final results = await _syncFromServer();
    final allOk = results.values.every((s) => s == true);

    if (!allOk) {
      state = SyncState(
        incomingStatus: {
          'categories': SyncStatus(label: 'Categories', success: results['categories']),
          'products': SyncStatus(label: 'Products', success: results['products']),
          'customers': SyncStatus(label: 'Customers', success: results['customers']),
          'stock': SyncStatus(label: 'Stock', success: results['stock']),
        },
        isSyncing: true,
      );
    }

    try {
      await _syncRepo.syncAll();
    } catch (_) {}

    await refresh();

    state = SyncState(
      pendingQueue: state.pendingQueue,
      pendingCount: state.pendingCount,
      failedCount: state.failedCount,
      syncedCount: state.syncedCount,
      lastSyncTime: state.lastSyncTime,
      isSyncing: false,
      syncResult: allOk,
      errorMessage: allOk ? null : 'Some data failed to sync from server. Local data preserved.',
      incomingStatus: {
        'categories': SyncStatus(label: 'Categories', success: results['categories']),
        'products': SyncStatus(label: 'Products', success: results['products']),
        'customers': SyncStatus(label: 'Customers', success: results['customers']),
        'stock': SyncStatus(label: 'Stock', success: results['stock']),
      },
    );

    return allOk;
  }

  Future<Map<String, bool>> _syncFromServer() async {
    final results = <String, bool>{};

    try {
      await _categoryRepo.refreshCategories();
      results['categories'] = true;
    } catch (_) {
      results['categories'] = false;
    }

    try {
      await _productRepo.refreshProducts();
      results['products'] = true;
    } catch (_) {
      results['products'] = false;
    }

    try {
      await _customerRepo.refreshCustomers();
      results['customers'] = true;
    } catch (_) {
      results['customers'] = false;
    }

    try {
      await _stockRepo.refreshStock();
      results['stock'] = true;
    } catch (_) {
      results['stock'] = false;
    }

    return results;
  }
}
