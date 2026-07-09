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
  final Map<int, TextEditingController> _itemDiscControllers = {};
  final Map<int, String?> _itemDiscTypes = {};
  int _lastItemCount = 0;
  String? _previousPendingUnit;

  @override
  void dispose() {
    _qtyController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    _discountValueController.dispose();
    for (final c in _itemDiscControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncItemControllers(int itemCount) {
    if (itemCount == _lastItemCount) return;
    for (final c in _itemDiscControllers.values) {
      c.dispose();
    }
    _itemDiscControllers.clear();
    _itemDiscTypes.clear();
    _lastItemCount = itemCount;
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
    _syncItemControllers(state.items.length);
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
          'Added Products',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              _buildItemHeader(theme),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  return _buildItemRow(context, index, state.items[index], theme);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          const SizedBox(width: 28), // for leading number
          Expanded(
            flex: 3,
            child: Text('Product', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text('Qty', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text('Rate', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text('Unit', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text('Disc. Value', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text('Disc. Type', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text('Amount', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.end),
          ),
          const SizedBox(width: 28), // for delete icon (fits the icon button size)
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, int index, SalesReturnItem item, ThemeData theme) {
    final gross = item.quantity * item.rate;

    if (!_itemDiscControllers.containsKey(index)) {
      _itemDiscControllers[index] = TextEditingController(
        text: item.discountValue > 0 ? item.discountValue.toString() : '',
      );
      _itemDiscTypes[index] = item.discountType;
    }
    final discCtrl = _itemDiscControllers[index]!;
    String? selectedType = _itemDiscTypes[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.productName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 20,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                  onPressed: () {
                    ref.read(salesReturnProvider.notifier).decrementItemQuantity(index);
                  },
                ),
                Text(
                  item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1),
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  iconSize: 20,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                  onPressed: () {
                    ref.read(salesReturnProvider.notifier).incrementItemQuantity(index);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              'Rs.${item.rate.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              item.unit ?? '',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: discCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                ),
                onChanged: (value) {
                  final val = double.tryParse(value) ?? 0;
                  ref.read(salesReturnProvider.notifier).setItemDiscount(
                    index, selectedType, val,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: selectedType,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'amount', child: Text('Rs.', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'percent', child: Text('%', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (value) {
                  _itemDiscTypes[index] = value;
                  ref.read(salesReturnProvider.notifier).setItemDiscount(
                    index, value, double.tryParse(discCtrl.text) ?? 0,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 60,
            child: Text(
              item.discountAmount > 0
                  ? '-Rs.${item.discountAmount.toStringAsFixed(0)}'
                  : 'Rs.${gross.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: item.discountAmount > 0 ? theme.colorScheme.error : null,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          IconButton(
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
            onPressed: () {
              ref.read(salesReturnProvider.notifier).removeItem(index);
            },
          ),
        ],
      ),
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