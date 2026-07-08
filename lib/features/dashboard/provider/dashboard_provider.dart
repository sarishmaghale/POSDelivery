import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_prefetch_service.dart';
import '../../../models/category.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/dashboard_repository.dart';

class DashboardState {
  final String driverName;
  final List<Category> categories;
  final int todaysDeliveries;
  final int estimatedBills;
  final int todaysSalesReturns;
  final int pendingSync;
  final int assignedCustomersCount;
  final int assignedProductsCount;
  final List<Map<String, dynamic>> remainingStock;
  final String? lastSyncTime;
  final bool isLoading;

  DashboardState({
    this.driverName = 'Ram Sharma',
    this.categories = const [],
    this.todaysDeliveries = 0,
    this.estimatedBills = 0,
    this.todaysSalesReturns = 0,
    this.pendingSync = 0,
    this.assignedCustomersCount = 0,
    this.assignedProductsCount = 0,
    this.remainingStock = const [],
    this.lastSyncTime,
    this.isLoading = false,
  });
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    dashboardRepo: ref.read(dashboardRepositoryProvider),
    categoryRepo: ref.read(categoryRepositoryProvider),
  );
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _dashboardRepo;
  final CategoryRepository _categoryRepo;

  DashboardNotifier({
    required DashboardRepository dashboardRepo,
    required CategoryRepository categoryRepo,
  })  : _dashboardRepo = dashboardRepo,
        _categoryRepo = categoryRepo,
        super(DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final cachedCategories = await _categoryRepo.getCachedCategories();
    final hasCache = cachedCategories.isNotEmpty;

    state = DashboardState(
      isLoading: !hasCache,
      categories: cachedCategories,
    );

    _prefetchImages(cachedCategories);
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    try {
      final categories = await _categoryRepo.refreshCategories();
      _prefetchImages(categories);

      var pending = 0;
      String? lastSync;
      String? driverName;
      int assignedProductCount = 0;

      try {
        final apiData = await _dashboardRepo.fetchDashboard();
        pending = apiData.pendingSync;
        lastSync = apiData.lastSyncTime;
        driverName = apiData.driverName;
        assignedProductCount = apiData.assignedProductIds.length;
      } catch (_) {}

      final deliveries = await _dashboardRepo.getTodaysDeliveries();
      final estimates = await _dashboardRepo.getEstimatedBillsCreated();
      final salesReturns = await _dashboardRepo.getTodaysSalesReturns();
      final assignedCustomers = await _dashboardRepo.getAssignedCustomersCount();
      final remainingStock = await _dashboardRepo.getRemainingAssignedStock();
      if (lastSync == null) {
        final dbLastSync = await _dashboardRepo.getLastSyncTime();
        lastSync = dbLastSync?.toIso8601String();
      }
      if (assignedProductCount == 0) {
        assignedProductCount = await _dashboardRepo.getAssignedProductsCount();
      }

      state = DashboardState(
        driverName: driverName ?? state.driverName,
        categories: categories,
        todaysDeliveries: deliveries,
        estimatedBills: estimates,
        todaysSalesReturns: salesReturns,
        pendingSync: pending,
        assignedCustomersCount: assignedCustomers,
        assignedProductsCount: assignedProductCount,
        remainingStock: remainingStock,
        lastSyncTime: lastSync,
      );
    } catch (_) {
      state = DashboardState(
        driverName: state.driverName,
        categories: state.categories,
        isLoading: false,
      );
    }
  }

  void _prefetchImages(List<Category> categories) {
    final urls = categories
        .where((c) => c.firstImageUrl != null && c.firstImageUrl!.isNotEmpty)
        .map((c) => c.firstImageUrl!)
        .toList();
    if (urls.isNotEmpty) {
      ImagePrefetchService().prefetchImages(urls);
    }
  }

  Future<void> refresh() async {
    state = DashboardState(isLoading: true, categories: state.categories);
    await _refreshInBackground();
  }
}
