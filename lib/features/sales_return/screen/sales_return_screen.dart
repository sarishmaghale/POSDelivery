import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/sales_return.dart';
import '../provider/sales_return_provider.dart';
import '../widgets/product_dropdown.dart';
import '../../delivery/widgets/customer_dropdown.dart';

class SalesReturnScreen extends ConsumerStatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  ConsumerState<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends ConsumerState<SalesReturnScreen> {
  final _qtyController = TextEditingController(text: '1');
  final _unitController = TextEditingController();
  final _rateController = TextEditingController();
  final _discountValueController = TextEditingController();
  String? _previousPendingUnit;
  double? _previousPendingRate;

  @override
  void dispose() {
    _qtyController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesReturnProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (state.pendingUnit != _previousPendingUnit) {
      _previousPendingUnit = state.pendingUnit;
      if (state.pendingUnit != null && state.pendingUnit != _unitController.text) {
        _unitController.text = state.pendingUnit!;
      }
    }

    if (state.pendingRate != _previousPendingRate) {
      _previousPendingRate = state.pendingRate;
      final rateText = state.pendingRate > 0
          ? state.pendingRate.toStringAsFixed(2)
          : '';
      if (rateText != _rateController.text) {
        _rateController.text = rateText;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesReturn),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.saved
              ? _buildSuccessState(theme, l10n)
              : _buildForm(state, theme, l10n),
    );
  }

  Widget _buildSuccessState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.salesReturnSaved,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.successfullyRecorded,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(salesReturnProvider.notifier).reset();
              _qtyController.text = '1';
              _unitController.clear();
              _rateController.clear();
              _discountValueController.clear();
            },
            child: Text(l10n.newSalesReturn),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/dashboard'),
            child: Text(l10n.backToDashboard),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(SalesReturnState state, ThemeData theme, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.customer,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        CustomerDropdown(
          customers: state.customers,
          selectedCustomer: state.selectedCustomer,
          onChanged: (customer) {
            ref.read(salesReturnProvider.notifier).selectCustomer(customer);
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Products',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductDropdown(
                  products: state.products,
                  selectedProduct: state.pendingProduct,
                  onChanged: (product) {
                    ref.read(salesReturnProvider.notifier).setPendingProduct(product);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final qty = double.tryParse(value) ?? 1;
                          ref.read(salesReturnProvider.notifier).setPendingQuantity(qty);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          ref.read(salesReturnProvider.notifier).setPendingUnit(
                            value.isEmpty ? null : value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Rate',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final rate = double.tryParse(value) ?? 0;
                          ref.read(salesReturnProvider.notifier).setPendingRate(rate);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.tonalIcon(
                      onPressed: state.pendingProduct == null
                          ? null
                          : () {
                              ref.read(salesReturnProvider.notifier).addItem();
                              _qtyController.text = '1';
                              _unitController.clear();
                              _rateController.clear();
                            },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildItemsSection(state, theme, l10n),
        const SizedBox(height: 16),
        _buildTotalsCard(state, theme),
        const SizedBox(height: 16),
        _buildHeaderDiscountSection(state, theme, l10n),
        const SizedBox(height: 24),
        Text(
          l10n.additionalDetails,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.reasonOptional,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    ref.read(salesReturnProvider.notifier).setReason(
                      value.isEmpty ? null : value,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.remarksOptional,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    ref.read(salesReturnProvider.notifier).setRemarks(
                      value.isEmpty ? null : value,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: state.isSaving
              ? null
              : () => _saveSalesReturn(context),
          icon: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(state.isSaving ? l10n.saving : l10n.saveSalesReturn),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(SalesReturnState state, ThemeData theme, AppLocalizations l10n) {
    if (state.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No products added',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Added Products (${state.items.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.hardEdge,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(item.productName, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  'Qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}'
                  '${item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : ''}'
                  '  •  Rs.${item.rate.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rs.${item.lineTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.discountAmount > 0 ? theme.colorScheme.error : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      tooltip: 'View details',
                      onPressed: () {
                        _showItemDetails(context, index, item);
                      },
                    ),
                  ],
                ),
                onTap: () => _showItemDetails(context, index, item),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showItemDetails(BuildContext context, int index, SalesReturnItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ItemDetailSheet(index: index, item: item),
    );
  }

  Widget _buildTotalsCard(SalesReturnState state, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalRow('Gross Total', state.grossTotal, theme, null),
            _totalRow('Item Discount', -state.totalItemDiscount, theme, theme.colorScheme.error),
            _totalRow('Header Discount', -state.discountAmount, theme, theme.colorScheme.error),
            const Divider(),
            _totalRow('Net Total', state.netTotal, theme,
                theme.colorScheme.primary, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, ThemeData theme, Color? color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            amount >= 0 ? 'Rs. ${amount.toStringAsFixed(2)}' : '- Rs. ${(-amount).toStringAsFixed(2)}',
            style: (bold ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600) : theme.textTheme.bodyMedium)?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDiscountSection(SalesReturnState state, ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Header Discount',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _discountValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Value',
                      hintText: '0',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final val = double.tryParse(value) ?? 0;
                      ref.read(salesReturnProvider.notifier).setDiscountValue(val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child:                   DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: state.discountType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('None')),
                      DropdownMenuItem(value: 'amount', child: Text('Amount (Rs.)')),
                      DropdownMenuItem(value: 'percent', child: Text('Percent (%)')),
                    ],
                    onChanged: (value) {
                      ref.read(salesReturnProvider.notifier).setDiscountType(value);
                      if (value == null) {
                        _discountValueController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSalesReturn(BuildContext context) async {
    final notifier = ref.read(salesReturnProvider.notifier);
    final success = await notifier.saveSalesReturn();

    if (!context.mounted) return;

    if (!success) {
      final errMsg = ref.read(salesReturnProvider).error;
      print(errMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg ?? AppLocalizations.of(context)!.failedToSaveSalesReturn),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _ItemDetailSheet extends ConsumerStatefulWidget {
  final int index;
  final SalesReturnItem item;

  const _ItemDetailSheet({required this.index, required this.item});

  @override
  ConsumerState<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends ConsumerState<_ItemDetailSheet> {
  late final TextEditingController _discCtrl;
  late final TextEditingController _rateCtrl;
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    _discCtrl = TextEditingController(
      text: widget.item.discountValue > 0 ? widget.item.discountValue.toString() : '',
    );
    _rateCtrl = TextEditingController(text: widget.item.rate.toStringAsFixed(2));
    _selectedType = widget.item.discountType;
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(salesReturnProvider);
    if (widget.index >= state.items.length) {
      return const SizedBox.shrink();
    }
    final item = state.items[widget.index];
    final notifier = ref.read(salesReturnProvider.notifier);

    final qtyText = item.quantity
        .toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Quantity', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                  onPressed: () {
                    final willRemove = item.quantity <= 1;
                    notifier.decrementItemQuantity(widget.index);
                    if (willRemove) Navigator.of(context).pop();
                  },
                ),
                Text(qtyText, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                  onPressed: () => notifier.incrementItemQuantity(widget.index),
                ),
                const Spacer(),
                Expanded(
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    decoration: const InputDecoration(
                      labelText: 'Rate',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => notifier.setItemRate(widget.index, double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.unit != null && item.unit!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Unit: ${item.unit}', style: theme.textTheme.bodyMedium),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    decoration: const InputDecoration(
                      labelText: 'Discount Value',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => notifier.setItemDiscount(
                      widget.index, _selectedType, double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Discount Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('None')),
                      DropdownMenuItem(value: 'amount', child: Text('Amount (Rs.)')),
                      DropdownMenuItem(value: 'percent', child: Text('Percent (%)')),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedType = v);
                      notifier.setItemDiscount(widget.index, v, double.tryParse(_discCtrl.text) ?? 0);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount: Rs. ${item.lineTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: () {
                    notifier.removeItem(widget.index);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Remove'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}