import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../delivery/provider/delivery_provider.dart';
import '../../sync/provider/sync_provider.dart';
import '../provider/estimate_provider.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final int? deliveryId;

  const EstimateScreen({super.key, this.deliveryId});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  final _paidAmountController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final langCode = Localizations.localeOf(context).languageCode;
      if (widget.deliveryId != null) {
        ref.read(estimateProvider.notifier).loadDelivery(widget.deliveryId!, languageCode: langCode);
      } else {
        _initFromDeliveryForm(ref, langCode);
      }
    });
  }

  void _initFromDeliveryForm(WidgetRef ref, String langCode) {
    final deliveryForm = ref.read(deliveryFormProvider);
    if (deliveryForm.cart.isEmpty) {
      context.go('/delivery');
      return;
    }

    final products = deliveryForm.products;
    final items = deliveryForm.cart.entries.map((e) {
      final product = products.where((p) => p.serverId == e.key).firstOrNull;
      return EstimateItemView(
        productId: e.key,
        productName: product?.localizedName(langCode) ?? AppLocalizations.of(context)!.unknown,
        quantity: e.value,
        unitPrice: deliveryForm.getUnitPrice(e.key),
        discountAmount: deliveryForm.productDiscounts[e.key] ?? 0,
        taxableType: product?.taxable ?? 0,
        unitId: deliveryForm.getSelectedUnitId(e.key) ?? product?.unitId,
        unitName: deliveryForm.getSelectedUnitName(e.key) ?? product?.unit,
      );
    }).toList();

    ref
        .read(estimateProvider.notifier)
        .initializeFromDeliveryForm(
          items: items,
          paymentModes: deliveryForm.paymentModes,
        );
    ref.read(estimateProvider.notifier).loadCustomers();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _syncControllers(EstimateState state) {
    if (state.isLoadingDelivery) {
      _controllersInitialized = false;
      return;
    }
    if (!_controllersInitialized) {
      _paidAmountController.text = state.paidAmount > 0
          ? state.paidAmount.toStringAsFixed(2)
          : '';
      _remarksController.text = state.remarks ?? '';
      _controllersInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimateProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    _syncControllers(state);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.billing)),
      body: _buildBody(state, theme, l10n),
    );
  }

  Widget _buildBody(
    EstimateState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (state.isLoadingDelivery) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.saved) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && context.mounted) {
            ref.read(estimateProvider.notifier).reset();
            context.pop();
          }
        },
        child: Center(
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
                l10n.invoiceSavedSuccessfully,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref.read(estimateProvider.notifier).reset();
                  context.pop();
                },
                child: Text(l10n.backToDashboard),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.customer != null) ...[
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      state.customer!.name.isNotEmpty
                          ? state.customer!.name[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.customer!.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.customer!.phone != null &&
                            state.customer!.phone!.isNotEmpty)
                          Text(
                            state.customer!.phone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(estimateProvider.notifier)
                        .selectCustomer(null),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Select Customer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search customer...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.customerSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => ref
                                  .read(estimateProvider.notifier)
                                  .setCustomerSearchQuery(''),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => ref
                        .read(estimateProvider.notifier)
                        .setCustomerSearchQuery(value),
                  ),
                  if (state.customerSearchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...state.filteredCustomers.map(
                      (c) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(c.name, style: theme.textTheme.bodyMedium),
                        subtitle: c.phone != null && c.phone!.isNotEmpty
                            ? Text(c.phone!, style: theme.textTheme.bodySmall)
                            : null,
                        onTap: () => ref
                            .read(estimateProvider.notifier)
                            .selectCustomer(c),
                      ),
                    ),
                    if (state.filteredCustomers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'No customers found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.items,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...state.items.map((item) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.qtyWithPrice(
                            item.rateIncTax.toStringAsFixed(2),
                            item.quantity.toStringAsFixed(0),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (item.discountAmount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Discount: -Rs. ${item.discountAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${item.netAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.grossAmount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Rs. ${state.grossTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: state.discountType,
                        decoration: InputDecoration(
                          labelText: l10n.discountType,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.none)),
                          DropdownMenuItem(
                            value: 'amount',
                            child: Text(l10n.amountRs),
                          ),
                          DropdownMenuItem(
                            value: 'percent',
                            child: Text(l10n.percent),
                          ),
                        ],
                        onChanged: (value) {
                          ref
                              .read(estimateProvider.notifier)
                              .setDiscountType(value);
                        },
                      ),
                    ),
                    if (state.discountType != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: state.discountType == 'percent'
                                ? l10n.percent
                                : l10n.amountRs,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            suffixText: state.discountType == 'percent'
                                ? '%'
                                : 'Rs.',
                          ),
                          onChanged: (value) {
                            final val = double.tryParse(value) ?? 0;
                            ref
                                .read(estimateProvider.notifier)
                                .setDiscountValue(val);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                if (state.totalProductDiscount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Product Discount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        '- Rs. ${state.totalProductDiscount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (state.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.discount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        '- Rs. ${state.discountAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (state.totalTax > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.tax,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Rs. ${state.totalTax.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs. ${state.netTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.paymentDetails,
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
                DropdownButtonFormField<String>(
                  initialValue: state.paymentMode?.isNotEmpty == true
                      ? state.paymentMode
                      : null,
                  decoration: InputDecoration(
                    labelText: l10n.paymentMode,
                    border: const OutlineInputBorder(),
                  ),
                  items: state.paymentModes.map((mode) {
                    return DropdownMenuItem(
                      value: mode.serverId,
                      child: Text(mode.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    ref.read(estimateProvider.notifier).setPaymentMode(value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _paidAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.paidAmount,
                    prefixText: 'Rs. ',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    ref.read(estimateProvider.notifier).setPaidAmount(amount);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _remarksController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.remarksOptional,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    ref
                        .read(estimateProvider.notifier)
                        .setRemarks(value.isEmpty ? null : value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: state.isSaving ? null : () => _saveInvoice(context),
          icon: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(state.isSaving ? l10n.saving : l10n.saveInvoice),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Future<void> _saveInvoice(BuildContext context) async {
    final success = await ref.read(estimateProvider.notifier).saveInvoice();

    if (!context.mounted) return;

    if (success) {
      ref.read(deliveryFormProvider.notifier).resetForm();
      ref.read(syncProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invoiceSavedSuccessfully),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSaveInvoice),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
