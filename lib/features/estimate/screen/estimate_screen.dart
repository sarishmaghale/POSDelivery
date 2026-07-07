import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../delivery/provider/delivery_provider.dart';
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
      if (widget.deliveryId != null) {
        ref
            .read(estimateProvider.notifier)
            .loadDelivery(widget.deliveryId!);
      } else {
        _initFromDeliveryForm(ref);
      }
    });
  }

  void _initFromDeliveryForm(WidgetRef ref) {
    final deliveryForm = ref.read(deliveryFormProvider);
    if (deliveryForm.selectedCustomer == null || deliveryForm.cart.isEmpty) {
      context.go('/delivery');
      return;
    }

    final products = deliveryForm.products;
    final items = deliveryForm.cart.entries.map((e) {
      final product = products.where((p) => p.serverId == e.key).firstOrNull;
      return EstimateItemView(
        productId: e.key,
        productName: product?.name ?? AppLocalizations.of(context)!.unknown,
        quantity: e.value,
        unitPrice: deliveryForm.getUnitPrice(e.key),
      );
    }).toList();

    ref.read(estimateProvider.notifier).initializeFromDeliveryForm(
      customer: deliveryForm.selectedCustomer!,
      items: items,
      paymentModes: deliveryForm.paymentModes,
    );
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
      appBar: AppBar(
        title: Text(l10n.billing),
      ),
      body: _buildBody(state, theme, l10n),
    );
  }

  Widget _buildBody(EstimateState state, ThemeData theme, AppLocalizations l10n) {
    if (state.isLoadingDelivery) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.saved) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && context.mounted) {
            ref.read(estimateProvider.notifier).reset();
            context.go('/dashboard');
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
                  context.go('/dashboard');
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deliveryNumber(state.delivery!.id?.toString() ?? 'New'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (state.customer != null) ...[
                  Text(
                    '${l10n.customerLabel} ${state.customer!.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (state.customer!.phone != null &&
                      state.customer!.phone!.isNotEmpty)
                    Text(
                      '${l10n.phone} ${state.customer!.phone}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
                Text(
                  '${l10n.date} ${state.delivery!.createdDate.formattedDateTime}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.paymentMode != null &&
                    state.paymentMode!.isNotEmpty)
                  Text(
                    '${l10n.payment} ${state.paymentModes.where((m) => m.serverId == state.paymentMode).firstOrNull?.name ?? state.paymentMode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (state.paidAmount > 0)
                  Text(
                    '${l10n.paid} Rs. ${state.paidAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
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
                          l10n.qtyWithPrice(item.quantity.toStringAsFixed(0), item.unitPrice.toStringAsFixed(2)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${item.lineTotal.toStringAsFixed(2)}',
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
                      child: DropdownButtonFormField<String>(
                        initialValue: state.discountType,
                        decoration: InputDecoration(
                          labelText: l10n.discountType,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.none)),
                          DropdownMenuItem(
                              value: 'amount', child: Text(l10n.amountRs)),
                          DropdownMenuItem(
                              value: 'percent', child: Text(l10n.percent)),
                        ],
                        onChanged: (value) {
                          ref
                              .read(estimateProvider.notifier)
                              .setDiscountType(value);
                        },
                      ),
                    ),
                    if (state.discountType != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            labelText: state.discountType == 'percent'
                                ? l10n.percent
                                : l10n.amountRs,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            suffixText:
                                state.discountType == 'percent' ? '%' : 'Rs.',
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
                  initialValue: state.paymentMode?.isNotEmpty == true ? state.paymentMode : null,
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                    ref.read(estimateProvider.notifier).setRemarks(
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
              : () => _saveInvoice(context),
          icon: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label:
              Text(state.isSaving ? l10n.saving : l10n.saveInvoice),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Future<void> _saveInvoice(BuildContext context) async {
    final deliveryForm = ref.read(deliveryFormProvider);
    final success =
        await ref.read(estimateProvider.notifier).saveInvoice(deliveryForm);

    if (!context.mounted) return;

    if (success) {
      ref.read(deliveryFormProvider.notifier).resetForm();
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
