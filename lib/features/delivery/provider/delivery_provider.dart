import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_prefetch_service.dart';
import '../../../models/category.dart';
import '../../../models/customer.dart';
import '../../../models/delivery.dart';
import '../../../models/product.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/delivery_repository.dart';
import '../../../repositories/product_repository.dart';

class DeliveryFormState {
  final Customer? selectedCustomer;
  final Category? selectedCategory;
  final List<Customer> customers;
  final List<Category> categories;
  final List<Product> products;
  final Map<String, double> cart;
  final Map<String, double> customPrices;
  final Map<String, double> stockMap;
  final String productSearchQuery;
  final bool isLoadingCustomers;
  final bool isLoadingProducts;
  final bool isSaving;
  final String? stockError;

  DeliveryFormState({
    this.selectedCustomer,
    this.selectedCategory,
    this.customers = const [],
    this.categories = const [],
    this.products = const [],
    this.cart = const {},
    this.customPrices = const {},
    this.stockMap = const {},
    this.productSearchQuery = '',
    this.isLoadingCustomers = false,
    this.isLoadingProducts = false,
    this.isSaving = false,
    this.stockError,
  });

  List<Product> get displayedProducts {
    if (selectedCategory == null) return products;
    return products
        .where((p) => p.categoryId == selectedCategory!.serverId)
        .toList();
  }

  List<Product> get filteredProducts {
    final prods = displayedProducts;
    if (productSearchQuery.isEmpty) return prods.take(6).toList();
    final query = productSearchQuery.toLowerCase();
    return prods
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  double getUnitPrice(String productId) {
    if (customPrices.containsKey(productId)) return customPrices[productId]!;
    final product = products.where((p) => p.serverId == productId).firstOrNull;
    return product?.unitPrice ?? 0;
  }

  double get estimatedTotal {
    double total = 0;
    for (final entry in cart.entries) {
      final price = getUnitPrice(entry.key);
      total += price * entry.value;
    }
    return total;
  }

  bool get isValid =>
      selectedCustomer != null && cart.values.any((q) => q > 0);

  double getRemainingQuantity(String productId) {
    return stockMap[productId] ?? 0;
  }
}

final deliveryFormProvider =
    StateNotifierProvider<DeliveryFormNotifier, DeliveryFormState>((ref) {
  return DeliveryFormNotifier(
    customerRepo: ref.read(customerRepositoryProvider),
    categoryRepo: ref.read(categoryRepositoryProvider),
    productRepo: ref.read(productRepositoryProvider),
    deliveryRepo: ref.read(deliveryRepositoryProvider),
  );
});

class DeliveryFormNotifier extends StateNotifier<DeliveryFormState> {
  final CustomerRepository _customerRepo;
  final CategoryRepository _categoryRepo;
  final ProductRepository _productRepo;
  final DeliveryRepository _deliveryRepo;

  DeliveryFormNotifier({
    required CustomerRepository customerRepo,
    required CategoryRepository categoryRepo,
    required ProductRepository productRepo,
    required DeliveryRepository deliveryRepo,
  })  : _customerRepo = customerRepo,
        _categoryRepo = categoryRepo,
        _productRepo = productRepo,
        _deliveryRepo = deliveryRepo,
        super(DeliveryFormState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = DeliveryFormState(isLoadingCustomers: true);

    try {
      final customers = await _customerRepo.getCustomers();
      var categories = await _categoryRepo.getCachedCategories();
      var products = await _loadAllProducts();

      if (categories.isEmpty) {
        try {
          categories = await _categoryRepo.getCategories();
        } catch (_) {}
      }

      if (products.isEmpty) {
        try {
          await _productRepo.getProducts();
          products = await _productRepo.getCachedProducts();
        } catch (_) {}
      }

      _prefetchProductImages(products);

      state = DeliveryFormState(
        customers: customers,
        categories: categories,
        products: products,
        stockMap: _buildStockMapFromProducts(products),
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    } catch (_) {
      state = DeliveryFormState(
        customers: await _customerRepo.getCachedCustomers(),
        categories: await _categoryRepo.getCachedCategories(),
        products: await _loadAllProducts(),
        stockMap: await _loadStockMap(),
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    }
  }

  Future<List<Product>> _loadAllProducts() async {
    try {
      return await _productRepo.getCachedProducts();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, double>> _loadStockMap() async {
    final products = await _loadAllProducts();
    return _buildStockMapFromProducts(products);
  }

  Map<String, double> _buildStockMapFromProducts(List<Product> products) {
    return {for (final p in products) p.serverId: p.stock};
  }

  void _prefetchProductImages(List<Product> products) {
    final urls = products
        .where((p) => p.firstImageUrl != null && p.firstImageUrl!.isNotEmpty)
        .map((p) => p.firstImageUrl!)
        .toList();
    if (urls.isNotEmpty) {
      ImagePrefetchService().prefetchImages(urls);
    }
  }

  Future<void> loadExistingDelivery(int deliveryId) async {
    state = DeliveryFormState(isLoadingCustomers: true);

    try {
      final delivery = await _deliveryRepo.getDeliveryById(deliveryId);
      if (delivery == null) {
        state = DeliveryFormState();
        return;
      }

      final customers = await _customerRepo.getCustomers();
      final categories = await _categoryRepo.getCachedCategories();
      final products = await _loadAllProducts();
      final stockMap = _buildStockMapFromProducts(products);
      final items = await _deliveryRepo.getDeliveryItems(deliveryId);

      final selectedCustomer = customers.cast<Customer?>().firstWhere(
            (c) => c?.serverId == delivery.customerId,
            orElse: () => null,
          );

      final cart = <String, double>{};
      final customPrices = <String, double>{};
      for (final item in items) {
        cart[item.productId] = (cart[item.productId] ?? 0) + item.quantity;
        if (item.unitPrice > 0) {
          customPrices[item.productId] = item.unitPrice;
        }
      }

      state = DeliveryFormState(
        selectedCustomer: selectedCustomer,
        customers: customers,
        categories: categories,
        products: products,
        stockMap: stockMap,
        customPrices: customPrices,
        cart: cart,
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    } catch (_) {
      state = DeliveryFormState(
        customers: await _customerRepo.getCachedCustomers(),
        categories: await _categoryRepo.getCachedCategories(),
        products: await _loadAllProducts(),
        stockMap: await _loadStockMap(),
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    }
  }

  void selectCustomer(Customer? customer) {
    state = DeliveryFormState(
      selectedCustomer: customer,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      stockMap: state.stockMap,
      productSearchQuery: state.productSearchQuery,
    );
  }

  void selectCategory(Category? category) {
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: category,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: state.cart,
      stockMap: state.stockMap,
      productSearchQuery: '',
    );
  }

  void setProductSearchQuery(String query) {
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: state.cart,
      stockMap: state.stockMap,
      customPrices: state.customPrices,
      productSearchQuery: query,
    );
  }

  void setCustomPrice(String productId, double price) {
    final updated = Map<String, double>.from(state.customPrices);
    if (price <= 0) {
      updated.remove(productId);
    } else {
      updated[productId] = price;
    }
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: state.cart,
      stockMap: state.stockMap,
      customPrices: updated,
      productSearchQuery: state.productSearchQuery,
    );
  }

  void addToCart(String productId, double quantity) {
    if (quantity <= 0) return;
    final currentQty = state.cart[productId] ?? 0;
    final newQty = currentQty + quantity;
    final remaining = state.getRemainingQuantity(productId);
    if (newQty > remaining) {
      state = DeliveryFormState(
        selectedCustomer: state.selectedCustomer,
        selectedCategory: state.selectedCategory,
        customers: state.customers,
        categories: state.categories,
        products: state.products,
        cart: state.cart,
        stockMap: state.stockMap,
        customPrices: state.customPrices,
        productSearchQuery: state.productSearchQuery,
        stockError: 'Entered quantity exceeds today\'s available stock.',
      );
      return;
    }
    final updated = Map<String, double>.from(state.cart);
    updated[productId] = newQty;
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: updated,
      stockMap: state.stockMap,
      productSearchQuery: state.productSearchQuery,
    );
  }

  void updateCartQuantity(String productId, double quantity) {
    final remaining = state.getRemainingQuantity(productId);
    if (quantity > remaining) {
      state = DeliveryFormState(
        selectedCustomer: state.selectedCustomer,
        selectedCategory: state.selectedCategory,
        customers: state.customers,
        categories: state.categories,
        products: state.products,
        cart: state.cart,
        stockMap: state.stockMap,
        customPrices: state.customPrices,
        productSearchQuery: state.productSearchQuery,
        stockError: 'Entered quantity exceeds today\'s available stock.',
      );
      return;
    }
    final updated = Map<String, double>.from(state.cart);
    if (quantity <= 0) {
      updated.remove(productId);
    } else {
      updated[productId] = quantity;
    }
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: updated,
      stockMap: state.stockMap,
      productSearchQuery: state.productSearchQuery,
    );
  }

  void removeFromCart(String productId) {
    final updated = Map<String, double>.from(state.cart)..remove(productId);
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: updated,
      stockMap: state.stockMap,
      productSearchQuery: state.productSearchQuery,
    );
  }

  void clearCart() {
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      stockMap: state.stockMap,
      productSearchQuery: state.productSearchQuery,
    );
  }

  void clearStockError() {
    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: state.cart,
      stockMap: state.stockMap,
      productSearchQuery: state.productSearchQuery,
    );
  }

  Future<DeliveryResult> saveDelivery() async {
    if (!state.isValid) return DeliveryResult(success: false);

    state = DeliveryFormState(
      selectedCustomer: state.selectedCustomer,
      selectedCategory: state.selectedCategory,
      customers: state.customers,
      categories: state.categories,
      products: state.products,
      cart: state.cart,
      stockMap: state.stockMap,
      customPrices: state.customPrices,
      isSaving: true,
    );

    try {
      final items = state.cart.entries.map((e) {
        final item = DeliveryItem();
        item.productId = e.key;
        item.quantity = e.value;
        item.unitPrice = state.getUnitPrice(e.key);
        return item;
      }).toList();

      final delivery = await _deliveryRepo.saveDelivery(
        customerId: state.selectedCustomer!.serverId,
        items: items,
      );

      for (final entry in state.cart.entries) {
        await _productRepo.deductStock(entry.key, entry.value);
      }

      final stockMap = await _loadStockMap();

      state = DeliveryFormState(
        customers: state.customers,
        categories: state.categories,
        products: state.products,
        stockMap: stockMap,
      );

      return DeliveryResult(success: true, deliveryId: delivery.id);
    } catch (e) {
      state = DeliveryFormState(
        selectedCustomer: state.selectedCustomer,
        selectedCategory: state.selectedCategory,
        customers: state.customers,
        categories: state.categories,
        products: state.products,
        cart: state.cart,
        stockMap: state.stockMap,
        customPrices: state.customPrices,
        isSaving: false,
      );
      return DeliveryResult(success: false, error: e.toString());
    }
  }
}

class DeliveryResult {
  final bool success;
  final int? deliveryId;
  final String? error;

  DeliveryResult({required this.success, this.deliveryId, this.error});
}
