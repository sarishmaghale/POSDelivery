import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer.dart';
import '../../../models/product.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/sales_return_repository.dart';

class SalesReturnState {
  final Customer? selectedCustomer;
  final Product? selectedProduct;
  final List<Customer> customers;
  final List<Product> products;
  final double quantity;
  final String? reason;
  final String? remarks;
  final bool isLoading;
  final bool isSaving;
  final bool saved;
  final String? error;

  SalesReturnState({
    this.selectedCustomer,
    this.selectedProduct,
    this.customers = const [],
    this.products = const [],
    this.quantity = 1,
    this.reason,
    this.remarks,
    this.isLoading = false,
    this.isSaving = false,
    this.saved = false,
    this.error,
  });

  bool get isValid =>
      selectedCustomer != null &&
      selectedProduct != null &&
      quantity > 0;
}

final salesReturnProvider =
    StateNotifierProvider<SalesReturnNotifier, SalesReturnState>((ref) {
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
      final customers = await _customerRepo.getCustomers();
      final products = await _productRepo.getCachedProducts();

      state = SalesReturnState(
        customers: customers,
        products: products,
        isLoading: false,
      );
    } catch (_) {
      state = SalesReturnState(
        customers: await _customerRepo.getCachedCustomers(),
        products: await _productRepo.getCachedProducts(),
        isLoading: false,
      );
    }
  }

  void selectCustomer(Customer? customer) {
    state = SalesReturnState(
      selectedCustomer: customer,
      selectedProduct: state.selectedProduct,
      customers: state.customers,
      products: state.products,
      quantity: state.quantity,
      reason: state.reason,
      remarks: state.remarks,
    );
  }

  void selectProduct(Product? product) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      selectedProduct: product,
      customers: state.customers,
      products: state.products,
      quantity: state.quantity,
      reason: state.reason,
      remarks: state.remarks,
    );
  }

  void setQuantity(double qty) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      selectedProduct: state.selectedProduct,
      customers: state.customers,
      products: state.products,
      quantity: qty,
      reason: state.reason,
      remarks: state.remarks,
    );
  }

  void setReason(String? reason) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      selectedProduct: state.selectedProduct,
      customers: state.customers,
      products: state.products,
      quantity: state.quantity,
      reason: reason,
      remarks: state.remarks,
    );
  }

  void setRemarks(String? remarks) {
    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      selectedProduct: state.selectedProduct,
      customers: state.customers,
      products: state.products,
      quantity: state.quantity,
      reason: state.reason,
      remarks: remarks,
    );
  }

  Future<bool> saveSalesReturn() async {
    if (!state.isValid) return false;

    state = SalesReturnState(
      selectedCustomer: state.selectedCustomer,
      selectedProduct: state.selectedProduct,
      customers: state.customers,
      products: state.products,
      quantity: state.quantity,
      reason: state.reason,
      remarks: state.remarks,
      isSaving: true,
    );

    try {
      await _salesReturnRepo.saveSalesReturn(
        customerId: state.selectedCustomer!.serverId,
        productId: state.selectedProduct!.serverId,
        quantity: state.quantity,
        reason: state.reason,
        remarks: state.remarks,
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
        selectedProduct: state.selectedProduct,
        customers: state.customers,
        products: state.products,
        quantity: state.quantity,
        reason: state.reason,
        remarks: state.remarks,
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
