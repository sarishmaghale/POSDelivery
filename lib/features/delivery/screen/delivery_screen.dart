import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart_item.dart';
import '../provider/delivery_provider.dart';
import '../widgets/customer_dropdown.dart';
import 'cart_screen.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  final int? deliveryId;

  const DeliveryScreen({super.key, this.deliveryId});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.deliveryId != null) {
        ref.read(deliveryFormProvider.notifier).loadExistingDelivery(widget.deliveryId!);
      } else {
        ref.read(deliveryFormProvider.notifier).resetForm();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryFormProvider);
    final theme = Theme.of(context);

    final cartItems = state.cart.entries.map((e) {
      final product = state.products.where((p) => p.serverId == e.key).firstOrNull;
      return CartItem(
        productId: e.key,
        productName: product?.name ?? 'Unknown',
        quantity: e.value,
        unitPrice: state.getUnitPrice(e.key),
      );
    }).toList();

    final title = state.isReadOnly
        ? 'Invoice #${widget.deliveryId}'
        : state.editingDeliveryId != null
            ? 'Edit Delivery'
            : 'Add Products';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!state.isReadOnly && state.cart.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${cartItems.fold<int>(0, (sum, item) => sum + item.quantity.toInt())}'),
                isLabelVisible: true,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              onPressed: () => _openCart(context),
            ),
        ],
      ),
      body: state.isLoadingCustomers
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(state, cartItems, theme),
    );
  }

  Widget _buildBody(DeliveryFormState state, List<CartItem> cartItems, ThemeData theme) {
    if (state.isReadOnly) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && context.mounted) {
            context.go('/delivery-history');
          }
        },
        child: _buildReadOnlyView(state, cartItems, theme),
      );
    }
    return _buildEditableForm(state, cartItems, theme);
  }

  Widget _buildReadOnlyView(DeliveryFormState state, List<CartItem> cartItems, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility, color: theme.colorScheme.onTertiaryContainer, size: 20),
              const SizedBox(width: 8),
              Text(
                'Viewing completed invoice',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(state.selectedCustomer?.name ?? 'Unknown',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...cartItems.map((item) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Qty: ${item.quantity.toStringAsFixed(0)} × Rs. ${item.unitPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text('Rs. ${item.lineTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer)),
                Text('Rs. ${state.estimatedTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableForm(DeliveryFormState state, List<CartItem> cartItems, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Customer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        CustomerDropdown(
          customers: state.customers,
          selectedCustomer: state.selectedCustomer,
          onChanged: (customer) {
            ref.read(deliveryFormProvider.notifier).selectCustomer(customer);
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (state.selectedCategory != null)
              TextButton.icon(
                onPressed: () => ref.read(deliveryFormProvider.notifier).selectCategory(null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear filter'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = state.selectedCategory == null;
                return FilterChip(
                  label: const Text('All'),
                  selected: isSelected,
                  onSelected: (_) => ref.read(deliveryFormProvider.notifier).selectCategory(null),
                );
              }
              final cat = state.categories[index - 1];
              final isSelected = state.selectedCategory?.serverId == cat.serverId;
              return FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (_) => ref.read(deliveryFormProvider.notifier)
                    .selectCategory(isSelected ? null : cat),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.productSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref.read(deliveryFormProvider.notifier).setProductSearchQuery(''),
                  )
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => ref.read(deliveryFormProvider.notifier).setProductSearchQuery(value),
        ),
        const SizedBox(height: 12),
        if (state.isLoadingProducts)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else
          _buildProductGrid(context, ref, state, theme),
        if (state.stockError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.stockError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => ref.read(deliveryFormProvider.notifier).clearStockError(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context, WidgetRef ref, DeliveryFormState state, ThemeData theme) {
    final products = state.filteredProducts;
    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              state.selectedCategory != null
                  ? 'No products in this category'
                  : 'Select a category to browse products',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final inCart = state.cart[product.serverId] ?? 0;
        final remaining = state.getRemainingQuantity(product.serverId);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: product.firstImageUrl != null && product.firstImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.firstImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildShimmerPlaceholder(theme),
                          errorWidget: (_, __, ___) => _buildPlaceholderIcon(theme),
                        )
                      : _buildPlaceholderIcon(theme),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${product.unitPrice.toStringAsFixed(0)}/${product.unit ?? 'unit'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Available: ${remaining.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: remaining > 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: remaining > 0
                            ? () {
                                ref.read(deliveryFormProvider.notifier)
                                    .addToCart(product.serverId, 1);
                              }
                            : null,
                        icon: Icon(
                          inCart > 0 ? Icons.check_circle : Icons.add_shopping_cart,
                          size: 16,
                        ),
                        label: Text(inCart > 0 ? 'Add more' : 'Add'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          backgroundColor: inCart > 0
                              ? theme.colorScheme.primaryContainer
                              : null,
                        ),
                      ),
                    ),
                    if (inCart > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'In cart: ${inCart.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderIcon(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    ).then((continueToBilling) {
      if (continueToBilling == true && context.mounted) {
        _continueToBilling(context);
      }
    });
  }

  Future<void> _continueToBilling(BuildContext context) async {
    if (!ref.read(deliveryFormProvider).isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer and add items')),
      );
      return;
    }
    GoRouter.of(context).go('/estimate');
  }
}
