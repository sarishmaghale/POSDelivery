import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer.dart';
import '../../../models/delivery.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/delivery_repository.dart';

class DeliveryHistoryScreen extends ConsumerStatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  ConsumerState<DeliveryHistoryScreen> createState() =>
      _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState
    extends ConsumerState<DeliveryHistoryScreen> {
  List<Delivery> _deliveries = [];
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final deliveries =
          await ref.read(deliveryRepositoryProvider).getDeliveriesByDate(
                DateTime.now(),
              );
      final customers =
          await ref.read(customerRepositoryProvider).getCachedCustomers();
      setState(() {
        _deliveries = deliveries;
        _customers = customers;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _customerName(String customerId) {
    final l10n = AppLocalizations.of(context)!;
    return _customers
            .cast<Customer?>()
            .firstWhere((c) => c?.serverId == customerId,
                orElse: () => null)
            ?.name ??
        l10n.customerId(customerId);
  }

  Future<int> _itemCount(int deliveryId) async {
    final items = await ref.read(deliveryRepositoryProvider).getDeliveryItems(deliveryId);
    return items.length;
  }

  Widget _subtitle(Delivery d) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<int>(
      future: _itemCount(d.id ?? 0),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final itemText = count == 1
            ? l10n.itemCount(count.toString())
            : l10n.itemCountPlural(count.toString());
        return Text(
          '${_customerName(d.customerId)} · $itemText\n${d.createdDate.formattedDateTime}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todaysDeliveries)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveries.isEmpty
              ? Center(
                  child: Text(
                    l10n.noDeliveriesForToday,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deliveries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final d = _deliveries[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: d.isSynced
                                ? Icon(Icons.cloud_done,
                                    color: theme
                                        .colorScheme.onPrimaryContainer)
                                : Icon(Icons.cloud_off,
                                    color: theme
                                        .colorScheme.onPrimaryContainer),
                          ),
                          title: Text(l10n.deliveryNumber(d.id.toString())),
                          subtitle: _subtitle(d),
                          onTap: () {
                            context.go('/delivery?deliveryId=${d.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
