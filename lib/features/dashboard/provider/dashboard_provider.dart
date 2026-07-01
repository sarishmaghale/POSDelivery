import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_prefetch_service.dart';
import '../../../dto/dashboard_response.dart';
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

      DashboardResponse? apiData;
      try {
        apiData = await _dashboardRepo.fetchDashboard();
      } catch (_) {}

      var deliveries = 0;
      var estimates = 0;
      var salesReturns = 0;
      var pending = 0;
      var assignedCustomers = 0;
      List<Map<String, dynamic>> remainingStock = [];
      String? lastSync;
      String? driverName;

      if (apiData != null) {
        deliveries = apiData.todaysDeliveries;
        estimates = apiData.estimatedBillsCreated;
        pending = apiData.pendingSync;
        lastSync = apiData.lastSyncTime;
        driverName = apiData.driverName;
      } else {
        deliveries = await _dashboardRepo.getTodaysDeliveries();
        estimates = await _dashboardRepo.getEstimatedBillsCreated();
        salesReturns = await _dashboardRepo.getTodaysSalesReturns();
        pending = await _dashboardRepo.getPendingSyncCount();
        assignedCustomers = await _dashboardRepo.getAssignedCustomersCount();
        remainingStock = await _dashboardRepo.getRemainingAssignedStock();
        final dbLastSync = await _dashboardRepo.getLastSyncTime();
        lastSync = dbLastSync?.toIso8601String();
      }

      state = DashboardState(
        driverName: driverName ?? state.driverName,
        categories: categories,
        todaysDeliveries: deliveries,
        estimatedBills: estimates,
        todaysSalesReturns: salesReturns,
        pendingSync: pending,
        assignedCustomersCount: assignedCustomers,
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
