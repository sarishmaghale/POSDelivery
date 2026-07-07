import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/estimate.dart';
import '../../../repositories/estimate_repository.dart';

class EstimateHistoryScreen extends ConsumerStatefulWidget {
  const EstimateHistoryScreen({super.key});

  @override
  ConsumerState<EstimateHistoryScreen> createState() =>
      _EstimateHistoryScreenState();
}

class _EstimateHistoryScreenState
    extends ConsumerState<EstimateHistoryScreen> {
  List<Estimate> _estimates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final estimates =
          await ref.read(estimateRepositoryProvider).getEstimatesByDate(
                DateTime.now(),
              );
      setState(() {
        _estimates = estimates;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todaysEstimates)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estimates.isEmpty
              ? Center(
                  child: Text(
                    l10n.noEstimatesForToday,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _estimates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = _estimates[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Text(
                              '#${e.id}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(l10n.estimateNumber(e.id.toString())),
                          subtitle: Text(
                            '${l10n.deliveryNumber(e.deliveryId.toString())} · Rs. ${e.estimatedTotal.toStringAsFixed(2)}\n${e.createdDate.formattedDateTime}',
                          ),
                          trailing: e.isSynced
                              ? Icon(Icons.cloud_done,
                                  color: theme.colorScheme.primary)
                              : Icon(Icons.cloud_off,
                                  color: theme.colorScheme.outline),
                          onTap: () {
                            context.push('/estimate?deliveryId=${e.deliveryId}');
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
