import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer.dart';
import '../../../models/payment_entry.dart';
import '../../../models/payment_mode.dart';
import '../../../models/product.dart';
import '../../../models/sales_return.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/payment_mode_repository.dart';
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
  final List<PaymentMode> paymentModes;
  final List<PaymentEntry> paymentEntries;
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
    this.paymentModes = const [],
    this.paymentEntries = const [],
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

  double get totalPaidAmount =>
      paymentEntries.fold<double>(0, (sum, e) => sum + e.amount);

  double get remainingAmount => netTotal - totalPaidAmount;
}

final salesReturnProvider =
    StateNotifierProvider.autoDispose<SalesReturnNotifier, SalesReturnState>((ref) {
  return SalesReturnNotifier(
    customerRepo: ref.read(customerRepositoryProvider),
    productRepo: ref.read(productRepositoryProvider),
    salesReturnRepo: ref.read(salesReturnRepositoryProvider),
    paymentModeRepo: ref.read(paymentModeRepositoryProvider),
  );
});

class SalesReturnNotifier extends StateNotifier<SalesReturnState> {
  final CustomerRepository _customerRepo;
  final ProductRepository _productRepo;
  final SalesReturnRepository _salesReturnRepo;
  final PaymentModeRepository _paymentModeRepo;

  SalesReturnNotifier({
    required this._customerRepo,
    required ProductRepository productRepo,
    required this._salesReturnRepo,
    required this._paymentModeRepo,
  })  : _productRepo = productRepo,
        super(SalesReturnState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = SalesReturnState(isLoading: true);

    try {
      final customers = await _customerRepo.getCachedCustomers();
      final products = await _productRepo.getCachedAllProducts();
      final paymentModes = await _paymentModeRepo.getPaymentModes();

      state = SalesReturnState(
        customers: customers,
        products: products,
        paymentModes: paymentModes,
        isLoading: false,
      );
    } catch (e) {
      print('[SalesReturn] loadInitialData error: $e');
      state = SalesReturnState(
        customers: await _customerRepo.getCachedCustomers(),
        products: await _productRepo.getCachedAllProducts(),
        paymentModes: await _paymentModeRepo.getPaymentModes(),
        isLoading: false,
      );
    }
  }

  SalesReturnState _copyWithAll({
    Customer? selectedCustomer,
    Product? pendingProduct,
    double? pendingQuantity,
    double? pendingRate,
    String? pendingUnit,
    List<Customer>? customers,
    List<Product>? products,
    List<SalesReturnItem>? items,
    String? reason,
    String? remarks,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    List<PaymentMode>? paymentModes,
    List<PaymentEntry>? paymentEntries,
    bool? isLoading,
    bool? isSaving,
    bool? isValid,
    bool? saved,
    String? error,
  }) {
    return SalesReturnState(
      selectedCustomer: selectedCustomer ?? state.selectedCustomer,
      pendingProduct: pendingProduct ?? state.pendingProduct,
      pendingQuantity: pendingQuantity ?? state.pendingQuantity,
      pendingRate: pendingRate ?? state.pendingRate,
      pendingUnit: pendingUnit ?? state.pendingUnit,
      customers: customers ?? state.customers,
      products: products ?? state.products,
      items: items ?? state.items,
      reason: reason ?? state.reason,
      remarks: remarks ?? state.remarks,
      discountType: discountType ?? state.discountType,
      discountValue: discountValue ?? state.discountValue,
      discountAmount: discountAmount ?? state.discountAmount,
      paymentModes: paymentModes ?? state.paymentModes,
      paymentEntries: paymentEntries ?? state.paymentEntries,
      isLoading: isLoading ?? state.isLoading,
      isSaving: isSaving ?? state.isSaving,
      isValid: isValid ?? state.isValid,
      saved: saved ?? state.saved,
      error: error,
    );
  }

  void selectCustomer(Customer? customer) {
    state = _copyWithAll(selectedCustomer: customer);
  }

  void setPendingProduct(Product? product) {
    state = _copyWithAll(
      pendingProduct: product,
      pendingRate: product?.unitPrice ?? 0,
      pendingUnit: product?.unit,
    );
  }

  void setPendingQuantity(double qty) {
    state = _copyWithAll(pendingQuantity: qty);
  }

  void setPendingRate(double rate) {
    state = _copyWithAll(pendingRate: rate);
  }

  void setPendingUnit(String? unit) {
    state = _copyWithAll(pendingUnit: unit);
  }

  void addPaymentEntry() {
    final updated = [
      ...state.paymentEntries,
      PaymentEntry(amount: state.remainingAmount > 0 ? state.remainingAmount : 0),
    ];
    state = _copyWithAll(paymentEntries: updated);
  }

  void removePaymentEntry(int index) {
    final updated = [...state.paymentEntries]..removeAt(index);
    state = _copyWithAll(paymentEntries: updated);
  }

  void updatePaymentEntryMode(int index, String? serverId, String? name) {
    final updated = [...state.paymentEntries];
    if (index >= 0 && index < updated.length) {
      updated[index] = PaymentEntry(
        paymentModeId: serverId,
        paymentModeName: name,
        amount: updated[index].amount,
      );
    }
    state = _copyWithAll(paymentEntries: updated);
  }

  void updatePaymentEntryAmount(int index, double amount) {
    final updated = [...state.paymentEntries];
    if (index >= 0 && index < updated.length) {
      updated[index] = PaymentEntry(
        paymentModeId: updated[index].paymentModeId,
        paymentModeName: updated[index].paymentModeName,
        amount: amount,
      );
    }
    state = _copyWithAll(paymentEntries: updated);
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
      state = _copyWithAll(
        pendingQuantity: 1,
        items: updated,
      );
    } else {
      final item = SalesReturnItem()
        ..productId = product.serverId
        ..productName = product.name
        ..quantity = state.pendingQuantity
        ..rate = state.pendingRate
        ..unitId = product.unitId
        ..unit = state.pendingUnit;

      state = _copyWithAll(
        pendingQuantity: 1,
        items: [...state.items, item],
      );
    }
    _recalcHeaderDiscount();
  }

  void removeItem(int index) {
    final updated = [...state.items];
    updated.removeAt(index);

    state = _copyWithAll(items: updated);
    _recalcHeaderDiscount();
  }

  void incrementItemQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updated = [...state.items];
    updated[index].quantity += 1;

    state = _copyWithAll(items: updated);
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

    state = _copyWithAll(items: updated);
    _recalcHeaderDiscount();
  }

  void setReason(String? reason) {
    state = _copyWithAll(reason: reason);
  }

  void setRemarks(String? remarks) {
    state = _copyWithAll(remarks: remarks);
  }

  void _recalcHeaderDiscount() {
    final netBeforeHeader = state.netTotalBeforeHeaderDiscount;
    final amount = _calcDiscountAmount(
        state.discountType, state.discountValue, netBeforeHeader);
    if (amount != state.discountAmount) {
      state = _copyWithAll(discountAmount: amount);
    }
  }

  double _calcDiscountAmount(String? type, double value, double netBeforeHeader) {
    if (type == null || value <= 0 || netBeforeHeader <= 0) return 0;
    if (type == 'percent') {
      return netBeforeHeader * (value / 100);
    }
    return value;
  }

  void setDiscountType(String? type) {
    state = _copyWithAll(
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
    state = _copyWithAll(
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

    state = _copyWithAll(items: updated);
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

    state = _copyWithAll(items: updated);
    _recalcHeaderDiscount();
  }

  String? validate() {
    if (state.selectedCustomer == null) return 'Please select a customer';
    if (state.items.isEmpty) return 'Please select at least one product';
    if (state.paymentEntries.isNotEmpty) {
      for (final entry in state.paymentEntries) {
        if (entry.paymentModeId == null || entry.paymentModeId!.isEmpty) {
          return 'Please select a payment mode for all entries';
        }
      }
    }
    return null;
  }

  Future<bool> saveSalesReturn() async {
    final validationError = validate();
    if (validationError != null) {
      state = _copyWithAll(error: validationError);
      return false;
    }

    state = _copyWithAll(isSaving: true);

    try {
      final String? payMode;
      if (state.paymentEntries.isEmpty) {
        payMode = null;
      } else if (state.paymentEntries.length == 1) {
        payMode = state.paymentEntries.first.paymentModeName;
      } else {
        payMode = 'Mix';
      }

      await _salesReturnRepo.saveSalesReturn(
        customerId: state.selectedCustomer!.serverId,
        items: state.items,
        reason: state.reason,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        paymentMode: payMode,
        paymentEntries: state.paymentEntries,
      );

      state = _copyWithAll(
        saved: true,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = _copyWithAll(
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
      paymentModes: state.paymentModes,
    );
  }
}
