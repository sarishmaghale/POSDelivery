import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_config.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final transactionDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final products = await ref.read(productRepositoryProvider).getProducts(
        customerId: ApiConfig.defaultCustomerId,
        transactionDate: transactionDate,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Text(
                    'No products available',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: product.firstImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      product.firstImageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Text(
                                        product.name.isNotEmpty
                                            ? product.name[0].toUpperCase()
                                            : '?',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    product.name.isNotEmpty
                                        ? product.name[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                            'Rs. ${product.unitPrice.toStringAsFixed(2)} · Stock: ${product.stock.toStringAsFixed(0)}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
