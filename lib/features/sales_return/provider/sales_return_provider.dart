import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/providers.dart';
import '../../../core/utils/tax_calculator.dart';
import '../../../dto/sales_invoice_request.dart';
import '../../../dto/sales_return_request.dart';
import '../../../models/customer.dart';
import '../../../models/payment_entry.dart';
import '../../../models/payment_mode.dart';
import '../../../models/product.dart';
import '../../../models/sales_return.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/payment_mode_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/sales_return_repository.dart';
import '../../location/location_provider.dart';

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
    apiService: ref.read(apiServiceProvider),
    locationState: ref.read(locationStateProvider),
  );
});

class SalesReturnNotifier extends StateNotifier<SalesReturnState> {
  final CustomerRepository _customerRepo;
  final ProductRepository _productRepo;
  final SalesReturnRepository _salesReturnRepo;
  final PaymentModeRepository _paymentModeRepo;
  final ApiService _apiService;
  final LocationState _locationState;

  SalesReturnNotifier({
    required this._customerRepo,
    required ProductRepository productRepo,
    required this._salesReturnRepo,
    required this._paymentModeRepo,
    required this._apiService,
    required this._locationState,
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

  void addItem({String languageCode = 'en'}) {
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
        ..productName = product.localizedName(languageCode)
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
    if (state.reason == null || state.reason!.trim().isEmpty) return 'Please enter a return reason';
    if (state.paymentEntries.isEmpty) return 'Please add at least one payment entry';
    for (final entry in state.paymentEntries) {
      if (entry.paymentModeId == null || entry.paymentModeId!.isEmpty) {
        return 'Please select a payment mode for all entries';
      }
      if (entry.amount <= 0) return 'Payment amount must be greater than 0';
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
      // Build product map for tax calculations
      final productsMap = <String, Product>{
        for (final p in state.products) p.serverId: p,
      };

      // Calculate item-level tax breakdown using tax_calculator
      final salesInvoiceItems = <SalesInvoiceItemRequest>[];
      double totalQty = 0;
      double totalGrossAmount = 0;
      double totalGrossAmountIncTax = 0;
      double totalDiscountExcTax = 0;
      double totalDiscountIncTax = 0;
      double totalTaxableAmount = 0;
      double totalNonTaxableAmount = 0;
      double totalTaxAmount = 0;
      double totalNetAmount = 0;

      for (final item in state.items) {
        final product = productsMap[item.productId];
        final taxableType = product?.taxable ?? 0;

        final tax = computeItemTax(
          rate: item.rate,
          quantity: item.quantity,
          discount: item.discountAmount,
          taxableType: taxableType,
          taxPercent: kDefaultTaxPercent,
        );

        final itemRequest = SalesInvoiceItemRequest(
          sku: product?.code,
          hasSerialNumber: false,
          serialNumber: '',
          refNo: item.productId,
          chalanNumber: product?.chalanNumber ?? '',
          lotNo: '',
          productId: item.productId,
          name: item.productName,
          quantity: item.quantity,
          unitId: item.unitId ?? product?.unitId ?? '',
          unitName: item.unit ?? product?.unit ?? '',
          categoryId: product?.categoryId ?? '',
          groupId: product?.categoryId ?? '00000000-0000-0000-0000-000000000000',
          rate: tax.rateExTax,
          rateIncludingTax: tax.rateIncTax,
          grossAmount: tax.grossAmount,
          grossAmountIncludingTax: tax.grossAmountIncTax,
          discountPercent: 0,
          discount: tax.discountExcTax,
          discountIncludingTax: tax.discountIncludingTax,
          discountType: 'Product',
          offerId: '',
          isCombo: false,
          isMaintainBatchLotNo: false,
          isNonConversableUnit: false,
          taxable: tax.taxableAmount,
          nonTaxable: tax.nonTaxableAmount,
          taxPercent: kDefaultTaxPercent,
          taxAmount: tax.taxAmount,
          netAmount: tax.netAmount,
          salesInvoiceItemTax: [
            SalesInvoiceItemTaxRequest(
              taxOrder: 1,
              name: 'VAT SALES',
              taxType: 'Percent',
              tax: kDefaultTaxPercent,
              taxableAmount: tax.taxableAmount,
              taxAmount: tax.taxAmount,
              netAmount: tax.netAmount,
            ),
          ],
          barcode: '',
          hsCode: '',
          attribute1: '',
          attribute2: '',
        );

        salesInvoiceItems.add(itemRequest);

        totalQty += item.quantity;
        totalGrossAmount += tax.grossAmount;
        totalGrossAmountIncTax += tax.grossAmountIncTax;
        totalDiscountExcTax += tax.discountExcTax;
        totalDiscountIncTax += tax.discountIncludingTax;
        totalTaxableAmount += tax.taxableAmount;
        totalNonTaxableAmount += tax.nonTaxableAmount;
        totalTaxAmount += tax.taxAmount;
        totalNetAmount += tax.netAmount;
      }

      // Add header discount to totals
      totalDiscountExcTax += state.discountAmount;
      totalDiscountIncTax += state.discountAmount;
      totalNetAmount -= state.discountAmount;

      // Build payment entries
      final salesInvoicePayments = <SalesInvoicePaymentRequest>[];
      for (final entry in state.paymentEntries) {
        final payModeName = entry.paymentModeName ?? 'Cash';
        final payModeId = entry.paymentModeId ?? ApiConfig.emptyGuid;
        salesInvoicePayments.add(SalesInvoicePaymentRequest(
          payMode: payModeName,
          paymentId: payModeId,
          amount: entry.amount,
        ));
      }

      // Determine payMode for header (use first payment mode or 'Mix')
      String payModeHeader = 'Cash';
      if (state.paymentEntries.isNotEmpty) {
        if (state.paymentEntries.length == 1) {
          payModeHeader = state.paymentEntries.first.paymentModeName ?? 'Cash';
        } else {
          payModeHeader = 'Mix';
        }
      }

      // Get current date time
      final now = DateTime.now();
      final transactionDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Get delivery boy ID from location provider
      final deliveryBoyId = _locationState.driverId ?? 'C3C7C7AA-7F7D-4EE2-8440-122DF4E6CB54';

      // Build the request
      final request = SalesReturnRequest(
        transactionDate: transactionDate,
        transactionDateBS: '', // Will be filled by server if needed
        type: 'Return',
        isReturn: true,
        isSettled: true,
        customerId: state.selectedCustomer!.serverId,
        customerName: state.selectedCustomer!.name,
        remarks: state.reason ?? state.remarks ?? '',
        outletId: ApiConfig.emptyGuid, // Using empty GUID like in billing
        totalQuantity: totalQty,
        totalGrossAmount: totalGrossAmount,
        totalGrossAmountIncludingTax: totalGrossAmountIncTax,
        totalDiscount: totalDiscountExcTax,
        totalDiscountIncludingTax: totalDiscountIncTax,
        totalTaxableAmount: totalTaxableAmount,
        totalNonTaxableAmount: totalNonTaxableAmount,
        totalTax: totalTaxAmount,
        totalNetAmount: totalNetAmount,
        totalPayableAmount: totalNetAmount,
        currencyName: 'NRs',
        payMode: payModeHeader,
        tenderAmount: totalNetAmount,
        changeAmount: 0,
        salesInvoiceTax: [
          SalesInvoiceTaxRequest(
            taxOrder: 1,
            name: 'VAT SALES',
            taxAmount: totalTaxAmount,
          ),
        ],
        salesInvoiceItem: salesInvoiceItems,
        salesInvoicePayment: salesInvoicePayments,
        currencyId: ApiConfig.defaultCurrencyId,
        volumeDiscount: state.discountAmount,
        deliveryBoyId: deliveryBoyId,
      );

      // Send to API
      final success = await _apiService.createSalesReturnV2(request);

      if (success) {
        // Also save locally
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
      } else {
        throw Exception('Failed to save sales return to server');
      }
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
