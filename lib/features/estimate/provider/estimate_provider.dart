import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_config.dart';
import '../../../dto/sales_invoice_request.dart';
import '../../../models/customer.dart';
import '../../../models/delivery.dart';
import '../../../models/estimate.dart';
import '../../../models/payment_mode.dart';
import '../../../models/product.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/delivery_repository.dart';
import '../../../repositories/estimate_repository.dart';
import '../../../repositories/payment_mode_repository.dart';
import '../../../repositories/product_repository.dart';

class EstimateItemView {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  double get grossAmount => quantity * unitPrice;
  double get lineTotal => grossAmount - discountAmount;

  EstimateItemView({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
  });
}

class EstimateState {
  final Delivery? delivery;
  final Customer? customer;
  final List<EstimateItemView> items;
  final List<Customer> customers;
  final String customerSearchQuery;
  final List<Delivery> pendingDeliveries;
  final List<PaymentMode> paymentModes;
  final String? paymentMode;
  final double paidAmount;
  final String? remarks;
  final String? discountType;
  final double discountValue;
  final double discountAmount;
  final bool isLoadingDelivery;
  final bool isLoadingCustomers;
  final bool isSaving;
  final bool saved;

  EstimateState({
    this.delivery,
    this.customer,
    this.items = const [],
    this.customers = const [],
    this.customerSearchQuery = '',
    this.pendingDeliveries = const [],
    this.paymentModes = const [],
    this.paymentMode,
    this.paidAmount = 0,
    this.remarks,
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.isLoadingDelivery = false,
    this.isLoadingCustomers = false,
    this.isSaving = false,
    this.saved = false,
  });

  double get grossTotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get totalGrossAmount =>
      items.fold<double>(0, (sum, item) => sum + item.grossAmount);

  double get totalProductDiscount =>
      items.fold<double>(0, (sum, item) => sum + item.discountAmount);

  double get netTotal => grossTotal - discountAmount;

  List<Customer> get filteredCustomers {
    if (customerSearchQuery.isEmpty) return [];
    final query = customerSearchQuery.toLowerCase();
    return customers
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.phone?.toLowerCase().contains(query) ?? false))
        .take(5)
        .toList();
  }
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
    required List<EstimateItemView> items,
    required List<PaymentMode> paymentModes,
  }) {
    final netAfterProductDiscount = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final draftDelivery = Delivery()
      ..customerId = ''
      ..createdDate = DateTime.now();
    state = EstimateState(
      delivery: draftDelivery,
      items: items,
      paymentModes: paymentModes,
      discountAmount: _calcDiscountAmount(null, 0, netAfterProductDiscount),
      isLoadingDelivery: false,
    );
  }

  Future<void> loadCustomers() async {
    try {
      final customers = await _customerRepo.getCustomers();
      state = EstimateState(
        delivery: state.delivery,
        customer: state.customer,
        items: state.items,
        customers: customers,
        pendingDeliveries: state.pendingDeliveries,
        paymentModes: state.paymentModes,
        paymentMode: state.paymentMode,
        paidAmount: state.paidAmount,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        isLoadingDelivery: false,
      );
    } catch (_) {
      final customers = await _customerRepo.getCachedCustomers();
      state = EstimateState(
        delivery: state.delivery,
        customer: state.customer,
        items: state.items,
        customers: customers,
        pendingDeliveries: state.pendingDeliveries,
        paymentModes: state.paymentModes,
        paymentMode: state.paymentMode,
        paidAmount: state.paidAmount,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        isLoadingDelivery: false,
      );
    }
  }

  void selectCustomer(Customer? customer) {
    state = EstimateState(
      delivery: state.delivery,
      customer: customer,
      items: state.items,
      customers: state.customers,
      pendingDeliveries: state.pendingDeliveries,
      paymentModes: state.paymentModes,
      paymentMode: state.paymentMode,
      paidAmount: state.paidAmount,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
      isLoadingDelivery: false,
    );
  }

  void setCustomerSearchQuery(String query) {
    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      customers: state.customers,
      customerSearchQuery: query,
      pendingDeliveries: state.pendingDeliveries,
      paymentModes: state.paymentModes,
      paymentMode: state.paymentMode,
      paidAmount: state.paidAmount,
      remarks: state.remarks,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
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
      customers: customers,
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
      customers: state.customers,
      customerSearchQuery: state.customerSearchQuery,
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
      customers: state.customers,
      customerSearchQuery: state.customerSearchQuery,
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
      customers: state.customers,
      customerSearchQuery: state.customerSearchQuery,
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
      customers: state.customers,
      customerSearchQuery: state.customerSearchQuery,
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
      customers: state.customers,
      customerSearchQuery: state.customerSearchQuery,
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

  Future<bool> saveInvoice() async {
    if (state.customer == null || state.items.isEmpty) return false;

    state = EstimateState(
      delivery: state.delivery,
      customer: state.customer,
      items: state.items,
      customers: state.customers,
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
      final deliveryItems = state.items.map((item) {
        final di = DeliveryItem();
        di.productId = item.productId;
        di.quantity = item.quantity;
        di.unitPrice = item.unitPrice;
        return di;
      }).toList();

      final delivery = await _deliveryRepo.saveDelivery(
        customerId: state.customer!.serverId,
        items: deliveryItems,
        paymentMode: state.paymentMode,
      );

      final estimateItems = state.items.map((item) {
        final eItem = EstimateItem();
        eItem.productId = item.productId;
        eItem.quantity = item.quantity;
        eItem.unitPrice = item.unitPrice;
        eItem.lineTotal = item.lineTotal;
        eItem.discountAmount = item.discountAmount;
        return eItem;
      }).toList();

      final payModeName = state.paymentMode != null
          ? (state.paymentModes.cast<PaymentMode?>().firstWhere(
                (m) => m?.serverId == state.paymentMode,
                orElse: () => null,
              )?.name ?? 'Cash')
          : 'Cash';

      final payModeId = state.paymentMode ?? ApiConfig.emptyGuid;

      final now = DateTime.now();
      final transactionDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final totalQty = state.items.fold<double>(
          0, (sum, item) => sum + item.quantity);
      final invoiceGrossAmount = state.totalGrossAmount;
      final totalProductDiscount = state.totalProductDiscount;
      final globalDiscount = state.discountAmount;
      final totalDiscount = totalProductDiscount + globalDiscount;
      final netAmount = invoiceGrossAmount - totalDiscount;

      final totalGross = state.totalGrossAmount;
      final productsMap = <String, Product>{
        for (final p in await _productRepo.getCachedProducts()) p.serverId: p,
      };
      final salesInvoiceItems = state.items.map((item) {
        final product = productsMap[item.productId];
        final proportion = totalGross > 0
            ? item.grossAmount / totalGross
            : 1.0 / state.items.length;
        final itemGlobalDiscount = globalDiscount * proportion;
        final itemNetAfterAll = item.lineTotal - itemGlobalDiscount;

        final taxableType = product?.taxable ?? 0;
        final rate = item.unitPrice;
        final quantity = item.quantity;
        final discount = item.discountAmount;
        const taxPercent = 13.0;

        double rateIncTax;
        double grossAmount;
        double grossAmountIncTax;
        double taxableAmount;
        double nonTaxableAmount;
        double taxAmount;

        double rateExTax;
        if (taxableType == 0) {
          rateExTax = rate;
          rateIncTax = rate * (1 + taxPercent / 100);
          grossAmount = rateExTax * quantity;
          grossAmountIncTax = rateIncTax * quantity;
          taxableAmount = grossAmount;
          nonTaxableAmount = 0;
          taxAmount = grossAmountIncTax - grossAmount;
        } else if (taxableType == 1) {
          rateIncTax = rate;
          rateExTax = rate / (1 + taxPercent / 100);
          grossAmountIncTax = rateIncTax * quantity;
          grossAmount = rateExTax * quantity;
          taxableAmount = grossAmount;
          nonTaxableAmount = 0;
          taxAmount = grossAmountIncTax - grossAmount;
        } else {
          rateExTax = rate;
          rateIncTax = rate;
          grossAmount = rateExTax * quantity;
          grossAmountIncTax = grossAmount;
          taxableAmount = 0;
          nonTaxableAmount = grossAmount;
          taxAmount = 0;
        }

        return SalesInvoiceItemRequest(
          refNo: item.productId,
          productId: item.productId,
          name: item.productName,
          quantity: quantity,
          unitId: product?.unitId ?? '',
          unitName: product?.unit ?? '',
          categoryId: product?.categoryId ?? '',
          rate: rateExTax,
          rateIncludingTax: rateIncTax,
          grossAmount: grossAmount,
          grossAmountIncludingTax: grossAmountIncTax,
          discount: discount,
          taxable: taxableAmount,
          nonTaxable: nonTaxableAmount,
          taxPercent: taxPercent,
          taxAmount: taxAmount,
          netAmount: itemNetAfterAll,
          salesInvoiceItemTax: [
            SalesInvoiceItemTaxRequest(
              taxableAmount: taxableAmount,
              taxAmount: taxAmount,
              netAmount: itemNetAfterAll,
            ),
          ],
        );
      }).toList();

      final totalTaxable = salesInvoiceItems.fold<double>(
          0, (sum, item) => sum + item.taxable);
      final totalNonTaxable = salesInvoiceItems.fold<double>(
          0, (sum, item) => sum + item.nonTaxable);
      final totalItemTax = salesInvoiceItems.fold<double>(
          0, (sum, item) => sum + item.taxAmount);

      final salesInvoiceRequest = SalesInvoiceRequest(
        transactionDate: transactionDate,
        customerId: state.customer!.serverId,
        customerName: state.customer!.name,
        outletId: ApiConfig.emptyGuid,
        totalQuantity: totalQty,
        totalGrossAmount: invoiceGrossAmount,
        totalGrossAmountIncludingTax: invoiceGrossAmount + totalItemTax,
        totalDiscount: totalDiscount,
        totalDiscountIncludingTax: totalDiscount,
        totalTaxableAmount: totalTaxable,
        totalNonTaxableAmount: totalNonTaxable,
        totalTax: totalItemTax,
        totalNetAmount: netAmount + totalItemTax,
        totalPayableAmount: netAmount + totalItemTax,
        payMode: payModeName,
        tenderAmount: netAmount + totalItemTax,
        salesInvoiceTax: [
          SalesInvoiceTaxRequest(taxAmount: totalItemTax),
        ],
        salesInvoiceItem: salesInvoiceItems,
        salesInvoicePayment: [
          SalesInvoicePaymentRequest(
            payMode: payModeName,
            paymentId: payModeId,
            amount: state.paidAmount > 0 ? state.paidAmount : netAmount + totalItemTax,
          ),
        ],
        currencyId: ApiConfig.defaultCurrencyId,
      );

      await _estimateRepo.saveEstimate(
        deliveryId: delivery.id!,
        items: estimateItems,
        paymentMode: state.paymentMode,
        paidAmount: state.paidAmount,
        remarks: state.remarks,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        salesInvoiceRequest: salesInvoiceRequest,
      );

      for (final item in state.items) {
        await _productRepo.deductStock(item.productId, item.quantity);
      }

      state = EstimateState(saved: true);
      return true;
    } catch (_) {
      state = EstimateState(
        delivery: state.delivery,
        customer: state.customer,
        items: state.items,
        customers: state.customers,
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
