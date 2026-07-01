import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Return'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.saved
              ? _buildSuccessState(theme)
              : _buildForm(state, theme),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
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
            'Sales Return Saved',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Successfully recorded',
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
            child: const Text('New Sales Return'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(SalesReturnState state, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Customer',
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
          'Product',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildProductDropdown(state, theme),
        const SizedBox(height: 24),
        Text(
          'Quantity',
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
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final qty = double.tryParse(value) ?? 1;
            ref.read(salesReturnProvider.notifier).setQuantity(qty);
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Additional Details',
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
                  decoration: const InputDecoration(
                    labelText: 'Reason (Optional)',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Remarks (Optional)',
                    border: OutlineInputBorder(),
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
          label: Text(state.isSaving ? 'Saving...' : 'Save Sales Return'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDropdown(SalesReturnState state, ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: state.selectedProduct?.serverId,
      decoration: const InputDecoration(
        labelText: 'Select Product',
        border: OutlineInputBorder(),
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
          content: const Text('Failed to save sales return'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
