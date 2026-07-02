import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer.dart';
import '../../../models/delivery.dart';
import '../../../models/estimate.dart';
import '../../../models/payment_mode.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/delivery_repository.dart';
import '../../../repositories/estimate_repository.dart';
import '../../../repositories/payment_mode_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../delivery/provider/delivery_provider.dart';

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
  final List<PaymentMode> paymentModes;
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
    this.paymentModes = const [],
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
    paymentModeRepo: ref.read(paymentModeRepositoryProvider),
    estimateRepo: ref.read(estimateRepositoryProvider),
  );
});

class EstimateNotifier extends StateNotifier<EstimateState> {
  final DeliveryRepository _deliveryRepo;
  final CustomerRepository _customerRepo;
  final ProductRepository _productRepo;
  final PaymentModeRepository _paymentModeRepo;
  final EstimateRepository _estimateRepo;

  EstimateNotifier({
    required DeliveryRepository deliveryRepo,
    required CustomerRepository customerRepo,
    required ProductRepository productRepo,
    required PaymentModeRepository paymentModeRepo,
    required EstimateRepository estimateRepo,
  })  : _deliveryRepo = deliveryRepo,
        _customerRepo = customerRepo,
        _productRepo = productRepo,
        _paymentModeRepo = paymentModeRepo,
        _estimateRepo = estimateRepo,
        super(EstimateState(isLoadingDelivery: true));

void initializeFromDeliveryForm({
    required Customer customer,
    required List<EstimateItemView> items,
    required List<PaymentMode> paymentModes,
  }) {
    final gross = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final draftDelivery = Delivery()
      ..customerId = customer.serverId
      ..createdDate = DateTime.now();
    state = EstimateState(
      delivery: draftDelivery,
      customer: customer,
      items: items,
      paymentModes: paymentModes,
      discountAmount: _calcDiscountAmount(null, 0, gross),
      isLoadingDelivery: false,
    );
  }

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
    final paymentModes = await _loadAllPaymentModes();
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
      paymentModes: paymentModes,
      paymentMode: (paymentMode ?? delivery.paymentMode)?.isNotEmpty == true
          ? (paymentMode ?? delivery.paymentMode)
          : null,
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

  Future<List<PaymentMode>> _loadAllPaymentModes() async {
    try {
      return await _paymentModeRepo.getPaymentModes();
    } catch (_) {
      return [];
    }
  }

  void setPaymentMode(String? mode) {
    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentModes: state.paymentModes,
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
      paymentModes: state.paymentModes,
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
      paymentModes: state.paymentModes,
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
      paymentModes: state.paymentModes,
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
      paymentModes: state.paymentModes,
      paymentMode: state.paymentMode,
      paidAmount: state.paidAmount,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: value,
      discountAmount: amount,
      isLoadingDelivery: false,
    );
  }

  Future<bool> saveInvoice(DeliveryFormState deliveryForm) async {
    if (state.customer == null || state.items.isEmpty) return false;
    if (deliveryForm.selectedCustomer == null) return false;

    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      pendingDeliveries: state.pendingDeliveries,
      paymentModes: state.paymentModes,
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
      final deliveryItems = deliveryForm.cart.entries.map((e) {
        final item = DeliveryItem();
        item.productId = e.key;
        item.quantity = e.value;
        item.unitPrice = deliveryForm.getUnitPrice(e.key);
        return item;
      }).toList();

      final delivery = await _deliveryRepo.saveDelivery(
        customerId: deliveryForm.selectedCustomer!.serverId,
        items: deliveryItems,
        paymentMode: state.paymentMode,
      );

      final estimateItems = state.items.map((item) {
        final eItem = EstimateItem();
        eItem.productId = item.productId;
        eItem.quantity = item.quantity;
        eItem.unitPrice = item.unitPrice;
        eItem.lineTotal = item.lineTotal;
        return eItem;
      }).toList();

      await _estimateRepo.saveEstimate(
        deliveryId: delivery.id!,
        items: estimateItems,
        paymentMode: state.paymentMode,
        paidAmount: state.paidAmount,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
      );

      for (final entry in deliveryForm.cart.entries) {
        await _productRepo.deductStock(entry.key, entry.value);
      }

      state = EstimateState(saved: true);
      return true;
    } catch (_) {
      state = EstimateState(
        delivery: state.delivery,
        customer: state.customer,
        items: state.items,
        pendingDeliveries: state.pendingDeliveries,
        paymentModes: state.paymentModes,
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
    state = EstimateState(isLoadingDelivery: true);
  }
}
