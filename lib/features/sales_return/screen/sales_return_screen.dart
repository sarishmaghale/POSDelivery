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
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                    const SizedBox(width: 8),
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
        if (state.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildItemsTable(state, theme, l10n),
          const SizedBox(height: 16),
          _buildTotalsCard(state, theme),
          const SizedBox(height: 16),
          _buildDiscountSection(state, theme, l10n),
        ],
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
          onPressed: state.isSaving || !state.isValid
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

  Widget _buildItemsTable(SalesReturnState state, ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Added Products',
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
              final gross = item.quantity * item.rate;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.productName,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (item.unit != null) item.unit,
                        if (item.rate > 0) 'Rate: Rs. ${item.rate.toStringAsFixed(2)}',
                        'Total: Rs. ${gross.toStringAsFixed(2)}',
                      ].join('  |  '),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.discountAmount > 0)
                      Text(
                        'Discount: -Rs. ${item.discountAmount.toStringAsFixed(2)}  |  Net: Rs. ${item.lineTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.discount_outlined,
                        color: item.discountAmount > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _showItemDiscountDialog(context, index, item),
                    ),
                    Text(
                      'Qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () {
                        ref.read(salesReturnProvider.notifier).removeItem(index);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(SalesReturnState state, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalRow('Gross Total', state.grossTotal, theme, null),
            if (state.totalItemDiscount > 0)
              _totalRow('Item Discount', -state.totalItemDiscount, theme, theme.colorScheme.error),
            if (state.discountAmount > 0)
              _totalRow('Header Discount', -state.discountAmount, theme, theme.colorScheme.error),
            const Divider(),
            _totalRow('Net Total', state.netTotal, theme,
                Theme.of(context).colorScheme.primary, bold: true),
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
            'Rs. ${amount.toStringAsFixed(2)}',
            style: (bold ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600) : theme.textTheme.bodyMedium)?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection(SalesReturnState state, ThemeData theme, AppLocalizations l10n) {
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
            DropdownButtonFormField<String?>(
              isExpanded: true,
              value: state.discountType,
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
              onChanged: (value) {
                ref.read(salesReturnProvider.notifier).setDiscountType(value);
                if (value == null) {
                  _discountValueController.clear();
                }
              },
            ),
            if (state.discountType != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _discountValueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: state.discountType == 'percent' ? 'Percent (%)' : 'Amount (Rs.)',
                  suffixText: state.discountType == 'percent' ? '%' : 'Rs.',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final val = double.tryParse(value) ?? 0;
                  ref.read(salesReturnProvider.notifier).setDiscountValue(val);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showItemDiscountDialog(BuildContext context, int index, SalesReturnItem item) {
    final typeController = TextEditingController(text: item.discountType ?? '');
    final valueController = TextEditingController(
      text: item.discountValue > 0 ? item.discountValue.toString() : '',
    );
    String? selectedType = item.discountType;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Discount - ${item.productName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: selectedType,
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
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value;
                        if (value == null) valueController.clear();
                      });
                    },
                  ),
                  if (selectedType != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: selectedType == 'percent' ? 'Percent (%)' : 'Amount (Rs.)',
                        suffixText: selectedType == 'percent' ? '%' : 'Rs.',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Gross: Rs. ${(item.quantity * item.rate).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final val = double.tryParse(valueController.text) ?? 0;
                    ref.read(salesReturnProvider.notifier).setItemDiscount(
                      index, selectedType, val,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveSalesReturn(BuildContext context) async {
    final success =
        await ref.read(salesReturnProvider.notifier).saveSalesReturn();

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSaveSalesReturn),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
