import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_service.dart';
import 'core/database/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/sync/provider/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(databaseService),
      ],
      child: const PosDeliveryApp(),
    ),
  );
}

class PosDeliveryApp extends ConsumerStatefulWidget {
  const PosDeliveryApp({super.key});

  @override
  ConsumerState<PosDeliveryApp> createState() =>
      _PosDeliveryAppState();
}

class _PosDeliveryAppState
    extends ConsumerState<PosDeliveryApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'POS Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouterProvider,
    );
  }
}
