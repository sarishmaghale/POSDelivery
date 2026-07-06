import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../provider/delivery_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryFormProvider);
    final theme = Theme.of(context);

    final cartItems = state.cart.entries.map((e) {
      final product = state.products.where((p) => p.serverId == e.key).firstOrNull;
      return CartItem(
        productId: e.key,
        productName: product?.name ?? 'Unknown',
        quantity: e.value,
        unitPrice: state.getUnitPrice(e.key),
        discountAmount: state.productDiscounts[e.key] ?? 0,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${cartItems.length})'),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(deliveryFormProvider.notifier).clearCart(),
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Text(
                'Cart is empty',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemCard(
                        item: item,
                        onQuantityChanged: (qty) {
                          ref.read(deliveryFormProvider.notifier)
                              .updateCartQuantity(item.productId, qty);
                        },
                        onUnitPriceChanged: (price) {
                          ref.read(deliveryFormProvider.notifier)
                              .setCustomPrice(item.productId, price);
                        },
                        onDiscountChanged: (discount) {
                          ref.read(deliveryFormProvider.notifier)
                              .setProductDiscount(item.productId, discount);
                        },
                        onRemove: () {
                          ref.read(deliveryFormProvider.notifier)
                              .removeFromCart(item.productId);
                        },
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs. ${state.estimatedTotal.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (state.selectedCustomer != null)
                            Text(
                              'Customer: ${state.selectedCustomer!.name}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: state.isValid
                                ? () => Navigator.pop(context, true)
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Continue'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<double> onUnitPriceChanged;
  final ValueChanged<double> onDiscountChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onUnitPriceChanged,
    required this.onDiscountChanged,
    required this.onRemove,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  late TextEditingController _qtyController;
  late TextEditingController _discountController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(0),
    );
    _discountController = TextEditingController(
      text: widget.item.discountAmount > 0
          ? widget.item.discountAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didUpdateWidget(_CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFocused) {
      _qtyController.text = widget.item.quantity.toStringAsFixed(0);
    }
    if (widget.item.discountAmount != oldWidget.item.discountAmount) {
      _discountController.text = widget.item.discountAmount > 0
          ? widget.item.discountAmount.toStringAsFixed(2)
          : '';
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _applyQty() {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty != widget.item.quantity) {
      widget.onQuantityChanged(qty);
    }
    setState(() => _isFocused = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.productName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showPriceEditor(context, theme),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rs. ${widget.item.unitPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 12, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: Focus(
                    onFocusChange: (focused) {
                      if (!focused) _applyQty();
                      setState(() => _isFocused = focused);
                    },
                    child: TextField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                        ],
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                          labelText: 'Qty',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (value) {
                          final qty = double.tryParse(value) ?? 0;
                          widget.onQuantityChanged(qty);
                        },
                        onSubmitted: (_) => _applyQty(),
                      ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      labelText: 'Discount',
                      prefixText: 'Rs. ',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                    onChanged: (value) {
                      final discount = double.tryParse(value) ?? 0;
                      widget.onDiscountChanged(discount);
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  'Line Total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs. ${widget.item.lineTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceEditor(BuildContext context, ThemeData theme) {
    final controller = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Price: ${widget.item.productName}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Unit Price',
            prefixText: 'Rs. ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(controller.text) ?? 0;
              if (price > 0) {
                widget.onUnitPriceChanged(price);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
