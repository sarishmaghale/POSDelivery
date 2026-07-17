import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/extensions.dart';
import '../../../core/utils/tax_calculator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer.dart';
import '../../../models/sales_return.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/sales_return_repository.dart';

class SalesReturnDetailScreen extends ConsumerStatefulWidget {
  final int salesReturnId;

  const SalesReturnDetailScreen({super.key, required this.salesReturnId});

  @override
  ConsumerState<SalesReturnDetailScreen> createState() =>
      _SalesReturnDetailScreenState();
}

class _SalesReturnDetailScreenState
    extends ConsumerState<SalesReturnDetailScreen> {
  SalesReturn? _salesReturn;
  Customer? _customer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final salesReturn = await ref
          .read(salesReturnRepositoryProvider)
          .getSalesReturnById(widget.salesReturnId);
      if (salesReturn == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.salesReturnNotFound;
          _isLoading = false;
        });
        return;
      }
      final customer = await ref
          .read(customerRepositoryProvider)
          .getCustomerById(salesReturn.customerId);
      setState(() {
        _salesReturn = salesReturn;
        _customer = customer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesReturnDetail),
        actions: [
          if (_salesReturn != null && !_salesReturn!.isSynced)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: l10n.syncNow,
              onPressed: () => _syncSalesReturn(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildDetailView(theme, l10n),
    );
  }

  Widget _buildDetailView(ThemeData theme, AppLocalizations l10n) {
    final sr = _salesReturn!;
    final itemsWithTax = sr.items.map((item) {
      final tax = computeItemTax(
        rate: item.rate,
        quantity: item.quantity,
        discount: item.discountAmount,
        taxableType: item.taxable,
      );
      return (item: item, tax: tax);
    }).toList();

    final totalGrossIncTax = itemsWithTax.fold<double>(
        0, (sum, e) => sum + e.tax.grossAmountIncTax);
    final totalDiscountIncTax = itemsWithTax.fold<double>(
        0, (sum, e) => sum + e.tax.discountIncludingTax);
    final totalTax = itemsWithTax.fold<double>(
        0, (sum, e) => sum + e.tax.taxAmount);
    final netTotal = totalGrossIncTax - totalDiscountIncTax - sr.discountAmount;

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
              Icon(
                Icons.visibility,
                color: theme.colorScheme.onTertiaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.viewingSalesReturn,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.salesReturnNumber(sr.id.toString()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (sr.createdDate != null)
                      Text(
                        sr.createdDate!.formattedDateTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (_customer != null) ...[
                  Text(
                    l10n.customer,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_customer!.name, style: theme.textTheme.bodyMedium),
                ],
                if (sr.paymentMode != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.paymentMode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(sr.paymentMode!, style: theme.textTheme.bodyMedium),
                ],
                if (sr.reason != null && sr.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.reason,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(sr.reason!, style: theme.textTheme.bodyMedium),
                ],
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
        ...itemsWithTax.map(
          (e) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.item.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.qtyWithPrice(
                            e.tax.rateIncTax.toStringAsFixed(2),
                            e.item.quantity.toStringAsFixed(0),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (e.item.discountAmount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Discount: -Rs. ${e.item.discountAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${e.tax.netAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                      'Rs. ${totalGrossIncTax.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (totalDiscountIncTax > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.productDiscount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        '- Rs. ${totalDiscountIncTax.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (sr.discountAmount > 0) ...[
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
                        '- Rs. ${sr.discountAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (totalTax > 0) ...[
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
                        'Rs. ${totalTax.toStringAsFixed(2)}',
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
                      'Rs. ${netTotal.toStringAsFixed(2)}',
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
        if (sr.paymentEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.paidAmount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        'Rs. ${sr.paymentEntries.fold<double>(0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...sr.paymentEntries.asMap().entries.map((entry) {
                    final payment = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(payment.paymentModeName ?? 'Cash',
                              style: theme.textTheme.bodyMedium),
                          Text(
                            'Rs. ${payment.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _syncSalesReturn(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // TODO: Implement sync logic
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.syncInitiated)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.syncFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}