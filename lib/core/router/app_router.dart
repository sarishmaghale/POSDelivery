import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/screen/dashboard_screen.dart';
import '../../features/delivery/screen/delivery_history_screen.dart';
import '../../features/delivery/screen/delivery_screen.dart';
import '../../features/estimate/screen/estimate_history_screen.dart';
import '../../features/estimate/screen/estimate_screen.dart';
import '../../features/profile/screen/profile_screen.dart';
import '../../features/sales_return/screen/sales_return_screen.dart';
import '../../features/sync/screen/sync_screen.dart';
import '../../l10n/app_localizations.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/delivery',
          pageBuilder: (context, state) {
            final deliveryId = int.tryParse(
                state.uri.queryParameters['deliveryId'] ?? '');
            return NoTransitionPage(
              child: DeliveryScreen(deliveryId: deliveryId),
            );
          },
        ),
        GoRoute(
          path: '/sales-return',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SalesReturnScreen(),
          ),
        ),
        GoRoute(
          path: '/sync',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SyncScreen(),
          ),
        ),
        GoRoute(
          path: '/delivery-history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DeliveryHistoryScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/delivery-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final deliveryId = int.tryParse(
            state.pathParameters['id'] ?? '');
        return DeliveryScreen(deliveryId: deliveryId);
      },
    ),
    GoRoute(
      path: '/estimate',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final deliveryId = int.tryParse(
            state.uri.queryParameters['deliveryId'] ?? '');
        return EstimateScreen(deliveryId: deliveryId);
      },
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/estimate-history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EstimateHistoryScreen(),
    ),
  ],
);

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/delivery')) return 1;
    if (location.startsWith('/sales-return')) return 2;
    if (location.startsWith('/sync')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/delivery');
      case 2:
        context.go('/sales-return');
      case 3:
        context.go('/sync');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: l10n.delivery,
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_return_outlined),
            selectedIcon: Icon(Icons.assignment_return),
            label: l10n.salesReturn,
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: l10n.sync,
          ),
        ],
      ),
    );
  }
}
