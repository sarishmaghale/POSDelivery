import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer.dart';
import '../../../models/delivery.dart';
import '../../../models/estimate.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/delivery_repository.dart';
import '../../../repositories/estimate_repository.dart';
import '../../../repositories/product_repository.dart';

class EstimateItemView {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  double get lineTotal => quantity * unitPrice;

  EstimateItemView({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}

class EstimateState {
  final Delivery? delivery;
  final Customer? customer;
  final List<EstimateItemView> items;
  final List<Delivery> pendingDeliveries;
  final String? paymentMode;
  final double paidAmount;
  final String? remarks;
  final String? discountType;
  final double discountValue;
  final double discountAmount;
  final bool isLoadingDelivery;
  final bool isSaving;
  final bool saved;

  EstimateState({
    this.delivery,
    this.customer,
    this.items = const [],
    this.pendingDeliveries = const [],
    this.paymentMode,
    this.paidAmount = 0,
    this.remarks,
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.isLoadingDelivery = false,
    this.isSaving = false,
    this.saved = false,
  });

  double get grossTotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get netTotal => grossTotal - discountAmount;
}

final estimateProvider =
    StateNotifierProvider<EstimateNotifier, EstimateState>((ref) {
  return EstimateNotifier(
    deliveryRepo: ref.read(deliveryRepositoryProvider),
    customerRepo: ref.read(customerRepositoryProvider),
    productRepo: ref.read(productRepositoryProvider),
    estimateRepo: ref.read(estimateRepositoryProvider),
  );
});

class EstimateNotifier extends StateNotifier<EstimateState> {
  final DeliveryRepository _deliveryRepo;
  final CustomerRepository _customerRepo;
  final ProductRepository _productRepo;
  final EstimateRepository _estimateRepo;

  EstimateNotifier({
    required DeliveryRepository deliveryRepo,
    required CustomerRepository customerRepo,
    required ProductRepository productRepo,
    required EstimateRepository estimateRepo,
  })  : _deliveryRepo = deliveryRepo,
        _customerRepo = customerRepo,
        _productRepo = productRepo,
        _estimateRepo = estimateRepo,
        super(EstimateState());

  Future<void> loadPendingDeliveries() async {
    final pending = await _deliveryRepo.getDeliveriesByDate(DateTime.now());
    state = EstimateState(pendingDeliveries: pending);
  }

  Future<void> loadDelivery(int deliveryId) async {
    state = EstimateState(isLoadingDelivery: true);

    final delivery = await _deliveryRepo.getDeliveryById(deliveryId);
    if (delivery == null) {
      state = EstimateState(isLoadingDelivery: false);
      return;
    }

    final customers = await _customerRepo.getCachedCustomers();
    final customer = customers.cast<Customer?>().firstWhere(
          (c) => c?.serverId == delivery.customerId,
          orElse: () => null,
        );

    final products = await _productRepo.getCachedProducts();
    final items = await _deliveryRepo.getDeliveryItems(deliveryId);

    final itemViews = items.map((item) {
      final product = products.where((p) => p.serverId == item.productId).firstOrNull;
      final price = item.unitPrice > 0 ? item.unitPrice : (product?.unitPrice ?? 0);
      return EstimateItemView(
        productId: item.productId,
        productName: product?.name ?? 'Unknown',
        quantity: item.quantity,
        unitPrice: price,
      );
    }).toList();

    String? paymentMode;
    double paidAmount = 0;
    String? remarks;
    String? discountType;
    double discountValue = 0;
    double discountAmount = 0;

    final existingEstimates = await _estimateRepo.getEstimatesByDelivery(deliveryId);
    if (existingEstimates.isNotEmpty) {
      final existing = existingEstimates.first;
      paymentMode = existing.paymentMode;
      paidAmount = existing.paidAmount;
      remarks = existing.remarks;
      discountType = existing.discountType;
      discountValue = existing.discountValue;
      discountAmount = existing.discountAmount;
    } else {
      final gross = itemViews.fold<double>(0, (sum, i) => sum + i.lineTotal);
      discountAmount = _calcDiscountAmount(discountType, discountValue, gross);
    }

    state = EstimateState(
      delivery: delivery,
      customer: customer,
      items: itemViews,
      paymentMode: paymentMode,
      paidAmount: paidAmount,
      remarks: remarks,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      isLoadingDelivery: false,
    );
  }

  double _calcDiscountAmount(String? type, double value, double gross) {
    if (value <= 0 || gross <= 0) return 0;
    if (type == 'percent') {
      return gross * (value / 100);
    }
    return value;
  }

  void setPaymentMode(String? mode) {
    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentMode: mode,
      paidAmount: state.paidAmount,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
      isLoadingDelivery: false,
    );
  }

  void setPaidAmount(double amount) {
    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentMode: state.paymentMode,
      paidAmount: amount,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
      isLoadingDelivery: false,
    );
  }

  void setRemarks(String? remarks) {
    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentMode: state.paymentMode,
      paidAmount: state.paidAmount,
      remarks: remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
      isLoadingDelivery: false,
    );
  }

  void setDiscountType(String? type) {
    final newValue = type == null ? 0.0 : state.discountValue;
    final newAmount = _calcDiscountAmount(type, newValue, state.grossTotal);
    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentMode: state.paymentMode,
      paidAmount: state.paidAmount,
      remarks: state.remarks,
      discountType: type,
      discountValue: newValue,
      discountAmount: newAmount,
      isLoadingDelivery: false,
    );
  }

  void setDiscountValue(double value) {
    final amount = _calcDiscountAmount(state.discountType, value, state.grossTotal);
    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentMode: state.paymentMode,
      paidAmount: state.paidAmount,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: value,
      discountAmount: amount,
      isLoadingDelivery: false,
    );
  }

  Future<bool> saveEstimate() async {
    if (state.delivery == null || state.items.isEmpty) return false;

    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentMode: state.paymentMode,
      paidAmount: state.paidAmount,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
      isLoadingDelivery: false,
      isSaving: true,
    );

    try {
      final estimateItems = state.items.map((item) {
        final eItem = EstimateItem();
        eItem.productId = item.productId;
        eItem.quantity = item.quantity;
        eItem.unitPrice = item.unitPrice;
        eItem.lineTotal = item.lineTotal;
        return eItem;
      }).toList();

      await _estimateRepo.saveEstimate(
        deliveryId: state.delivery!.id!,
        items: estimateItems,
        paymentMode: state.paymentMode,
        paidAmount: state.paidAmount,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
      );

      state = EstimateState(saved: true);
      return true;
    } catch (_) {
      state = EstimateState(
        delivery: state.delivery,
        customer: state.customer,
        items: state.items,
        pendingDeliveries: state.pendingDeliveries,
        paymentMode: state.paymentMode,
        paidAmount: state.paidAmount,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        isLoadingDelivery: false,
        isSaving: false,
      );
      return false;
    }
  }

  void reset() {
    state = EstimateState();
  }
}
