import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/dashboard_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/stat_card.dart';
import '../../location/location_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final locationState = ref.watch(locationStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              locationState.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: locationState.isOnline ? Colors.green : Colors.red,
            ),
            tooltip: locationState.isOnline ? 'Online' : 'Offline',
            onPressed: () => ref.read(locationStateProvider.notifier).manualSync(),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDriverHeader(state, theme),
            const SizedBox(height: 16),
            _buildLocationTrackingSection(locationState, theme),
            const SizedBox(height: 20),
            _buildStatsRow(state, theme),
            const SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverHeader(DashboardState state, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                state.driverName.isNotEmpty
                    ? state.driverName[0].toUpperCase()
                    : 'R',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
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
                    'Welcome back,',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    state.driverName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrackingSection(LocationState locationState, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: locationState.isTracking ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: locationState.isTracking ? Colors.green.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    locationState.isTracking ? Icons.track_changes : Icons.location_off,
                    color: locationState.isTracking ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locationState.isTracking ? 'Your location is being tracked' : 'Please start duty',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: locationState.isTracking ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (locationState.pendingSyncCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${locationState.pendingSyncCount} pending',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: locationState.isTracking
                        ? null
                        : () => ref.read(locationStateProvider.notifier).startTracking(),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Duty'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: locationState.isTracking
                        ? () => ref.read(locationStateProvider.notifier).stopTracking()
                        : null,
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Stop Duty'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: locationState.pendingSyncCount > 0
                    ? () => ref.read(locationStateProvider.notifier).manualSync()
                    : null,
                icon: const Icon(Icons.sync, size: 18),
                label: Text(
                  locationState.pendingSyncCount > 0
                      ? 'Sync Now (${locationState.pendingSyncCount} pending)'
                      : 'No pending data to sync',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (locationState.error != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  locationState.error!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardState state, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: "Today's Deliveries",
                value: state.todaysDeliveries.toString(),
                icon: Icons.local_shipping,
                onTap: () => context.push('/delivery-history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Sales Returns',
                value: state.todaysSalesReturns.toString(),
                icon: Icons.assignment_return,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Categories',
                value: state.categories.length.toString(),
                icon: Icons.category,
                onTap: () => context.go('/delivery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Customers',
                value: state.assignedCustomersCount.toString(),
                icon: Icons.people,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Products',
                value: state.assignedProductsCount.toString(),
                icon: Icons.inventory_2,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        QuickActionCard(
          title: 'New Delivery',
          subtitle: 'Create a new delivery',
          icon: Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.tertiaryContainer,
          onTap: () => context.go('/delivery'),
        ),
        const SizedBox(height: 8),
        QuickActionCard(
          title: 'Sales Return',
          subtitle: 'Record a sales return',
          icon: Icons.assignment_return,
          color: Theme.of(context).colorScheme.secondaryContainer,
          onTap: () => context.go('/sales-return'),
        ),
        const SizedBox(height: 8),
        QuickActionCard(
          title: 'Sync',
          subtitle: 'Sync pending data',
          icon: Icons.sync,
          color: Theme.of(context).colorScheme.tertiaryContainer,
          onTap: () => context.go('/sync'),
        ),
      ],
    );
  }
}
