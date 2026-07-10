import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer.dart';
import '../../../models/product.dart';
import '../../../models/sales_return.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/sales_return_repository.dart';

class SalesReturnState {
  final Customer? selectedCustomer;
  final Product? pendingProduct;
  final double pendingQuantity;
  final double pendingRate;
  final String? pendingUnit;
  final List<Customer> customers;
  final List<Product> products;
  final List<SalesReturnItem> items;
  final String? reason;
  final String? remarks;
  final String? discountType;
  final double discountValue;
  final double discountAmount;
  final bool isLoading;
  final bool isSaving;
  final bool isValid;
  final bool saved;
  final String? error;

  SalesReturnState({
    this.selectedCustomer,
    this.pendingProduct,
    this.pendingQuantity = 1,
    this.pendingRate = 0,
    this.pendingUnit,
    this.customers = const [],
    this.products = const [],
    this.items = const [],
    this.reason,
    this.remarks,
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.isValid=true,
    this.saved = false,
    this.error,
  });

  double get grossTotal =>
      items.fold<double>(0, (sum, item) => sum + item.quantity * item.rate);

  double get totalItemDiscount =>
      items.fold<double>(0, (sum, item) => sum + item.discountAmount);

  double get netTotalBeforeHeaderDiscount => grossTotal - totalItemDiscount;

  double get netTotal => netTotalBeforeHeaderDiscount - discountAmount;
}

final salesReturnProvider =
    StateNotifierProvider.autoDispose<SalesReturnNotifier, SalesReturnState>((ref) {
  return SalesReturnNotifier(
    customerRepo: ref.read(customerRepositoryProvider),
    productRepo: ref.read(productRepositoryProvider),
    salesReturnRepo: ref.read(salesReturnRepositoryProvider),
  );
});

class SalesReturnNotifier extends StateNotifier<SalesReturnState> {
  final CustomerRepository _customerRepo;
  final ProductRepository _productRepo;
  final SalesReturnRepository _salesReturnRepo;

  SalesReturnNotifier({
    required CustomerRepository customerRepo,
    required ProductRepository productRepo,
    required SalesReturnRepository salesReturnRepo,
  })  : _customerRepo = customerRepo,
        _productRepo = productRepo,
        _salesReturnRepo = salesReturnRepo,
        super(SalesReturnState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = SalesReturnState(isLoading: true);

    try {
      final customers = await _customerRepo.getCachedCustomers();
      final products = await _productRepo.getCachedAllProducts();

      state = SalesReturnState(
        customers: customers,
        products: products,
        isLoading: false,
      );
    } catch (e) {
      print('[SalesReturn] loadInitialData error: $e');
      state = SalesReturnState(
        customers: await _customerRepo.getCachedCustomers(),
        products: await _productRepo.getCachedAllProducts(),
        isLoading: false,
      );
    }
  }

  void selectCustomer(Customer? customer) {
    state = SalesReturnState(
      selectedCustomer: customer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void setPendingProduct(Product? product) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: product,
      pendingQuantity: state.pendingQuantity,
      pendingRate: product?.unitPrice ?? 0,
      pendingUnit: product?.unit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void setPendingQuantity(double qty) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: qty,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void setPendingRate(double rate) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: rate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void setPendingUnit(String? unit) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: unit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void addItem() {
    final product = state.pendingProduct;
    if (product == null || state.pendingQuantity <= 0) return;

    final existingIndex = state.items.indexWhere(
      (item) =>
          item.productId == product.serverId &&
          item.rate == state.pendingRate &&
          item.unit == state.pendingUnit,
    );

    if (existingIndex >= 0) {
      final updated = [...state.items];
      final existing = updated[existingIndex];
      existing.quantity += state.pendingQuantity;
      state = SalesReturnState(
        selectedCustomer: state.selectedCustomer,
        pendingProduct: state.pendingProduct,
        pendingQuantity: state.pendingQuantity,
        pendingRate: state.pendingRate,
        pendingUnit: state.pendingUnit,
        customers: state.customers,
        products: state.products,
        items: updated,
        reason: state.reason,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
      );
    } else {
      final item = SalesReturnItem()
        ..productId = product.serverId
        ..productName = product.name
        ..quantity = state.pendingQuantity
        ..rate = state.pendingRate
        ..unitId = product.unitId
        ..unit = state.pendingUnit;

      state = SalesReturnState(
        selectedCustomer: state.selectedCustomer,
        pendingProduct: state.pendingProduct,
        pendingQuantity: state.pendingQuantity,
        pendingRate: state.pendingRate,
        pendingUnit: state.pendingUnit,
        customers: state.customers,
        products: state.products,
        items: [...state.items, item],
        reason: state.reason,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
      );
    }
    _recalcHeaderDiscount();
  }

  void removeItem(int index) {
    final updated = [...state.items];
    updated.removeAt(index);

    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: updated,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
    _recalcHeaderDiscount();
  }

  void incrementItemQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updated = [...state.items];
    updated[index].quantity += 1;

    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: updated,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
    _recalcHeaderDiscount();
  }

  void decrementItemQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updated = [...state.items];
    if (updated[index].quantity <= 1) {
      updated.removeAt(index);
    } else {
      updated[index].quantity -= 1;
    }

    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: updated,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
    _recalcHeaderDiscount();
  }

  void setReason(String? reason) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void setRemarks(String? remarks) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void _recalcHeaderDiscount() {
    final netBeforeHeader = state.netTotalBeforeHeaderDiscount;
    final amount = _calcDiscountAmount(
        state.discountType, state.discountValue, netBeforeHeader);
    if (amount != state.discountAmount) {
      state = SalesReturnState(
        selectedCustomer: state.selectedCustomer,
        pendingProduct: state.pendingProduct,
        pendingQuantity: state.pendingQuantity,
        pendingRate: state.pendingRate,
        pendingUnit: state.pendingUnit,
        customers: state.customers,
        products: state.products,
        items: state.items,
        reason: state.reason,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: amount,
      );
    }
  }

  double _calcDiscountAmount(String? type, double value, double netBeforeHeader) {
    if (value <= 0 || netBeforeHeader <= 0) return 0;
    if (type == 'percent') {
      return netBeforeHeader * (value / 100);
    }
    return value;
  }

  void setDiscountType(String? type) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: type,
      discountValue: type == null ? 0 : state.discountValue,
      discountAmount: type == null
          ? 0
          : _calcDiscountAmount(type, state.discountValue, state.netTotalBeforeHeaderDiscount),
    );
  }

  void setDiscountValue(double value) {
    final amount = _calcDiscountAmount(
        state.discountType, value, state.netTotalBeforeHeaderDiscount);
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: value,
      discountAmount: amount,
    );
  }

  void setItemRate(int index, double rate) {
    if (index < 0 || index >= state.items.length) return;
    final updated = [...state.items];
    final item = updated[index];
    item.rate = rate;
    final gross = item.quantity * item.rate;
    item.discountAmount = item.discountType == null
        ? 0
        : _calcDiscountAmount(item.discountType, item.discountValue, gross);
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: updated,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
    _recalcHeaderDiscount();
  }

  void setItemDiscount(int index, String? type, double value) {
    if (index < 0 || index >= state.items.length) return;
    final updated = [...state.items];
    final item = updated[index];
    final gross = item.quantity * item.rate;
    item.discountType = type;
    item.discountValue = type == null ? 0 : value;
    item.discountAmount = type == null
        ? 0
        : _calcDiscountAmount(type, value, gross);

    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingProduct: state.pendingProduct,
      pendingQuantity: state.pendingQuantity,
      pendingRate: state.pendingRate,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: updated,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
    _recalcHeaderDiscount();
  }

  String? validate() {
    if (state.selectedCustomer == null) return 'Please select a customer';
    if (state.items.isEmpty) return 'Please select at least one product';
    return null;
  }

  Future<bool> saveSalesReturn() async {
    final validationError = validate();
    if (validationError != null) {
      state = SalesReturnState(
        selectedCustomer: state.selectedCustomer,
        pendingUnit: state.pendingUnit,
        customers: state.customers,
        products: state.products,
        items: state.items,
        reason: state.reason,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        error: validationError,
      );
      return false;
    }

    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      pendingUnit: state.pendingUnit,
      customers: state.customers,
      products: state.products,
      items: state.items,
      reason: state.reason,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
      isSaving: true,
    );

    try {
      await _salesReturnRepo.saveSalesReturn(
        customerId: state.selectedCustomer!.serverId,
        items: state.items,
        reason: state.reason,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
      );

      state = SalesReturnState(
        customers: state.customers,
        products: state.products,
        saved: true,
      );
      return true;
    } catch (e) {
      state = SalesReturnState(
        selectedCustomer: state.selectedCustomer,
        pendingUnit: state.pendingUnit,
        customers: state.customers,
        products: state.products,
        items: state.items,
        reason: state.reason,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = SalesReturnState(
      customers: state.customers,
      products: state.products,
    );
  }
}
