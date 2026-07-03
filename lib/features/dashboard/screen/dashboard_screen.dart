import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/dashboard_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/stat_card.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
