import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../provider/sales_return_provider.dart';
import '../../delivery/widgets/customer_dropdown.dart';

class SalesReturnScreen extends ConsumerStatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  ConsumerState<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends ConsumerState<SalesReturnScreen> {
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesReturnProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
              _quantityController.text = '1';
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
          l10n.product,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildProductDropdown(state, theme, l10n),
        const SizedBox(height: 24),
        Text(
          l10n.quantity,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: l10n.quantity,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            final qty = double.tryParse(value) ?? 1;
            ref.read(salesReturnProvider.notifier).setQuantity(qty);
          },
        ),
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

  Widget _buildProductDropdown(SalesReturnState state, ThemeData theme, AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: state.selectedProduct?.serverId,
      decoration: InputDecoration(
        labelText: l10n.selectProduct,
        border: const OutlineInputBorder(),
      ),
      items: state.products.map((product) {
        return DropdownMenuItem(
          value: product.serverId,
          child: Text(product.name),
        );
      }).toList(),
      onChanged: (productId) {
        final product = state.products.firstWhere(
          (p) => p.serverId == productId,
          orElse: () => state.products.first,
        );
        ref.read(salesReturnProvider.notifier).selectProduct(product);
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
