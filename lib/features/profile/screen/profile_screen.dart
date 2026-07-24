import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.language),
              subtitle: Text(
                currentLocale.languageCode == 'ne' ? l10n.nepali : l10n.english,
              ),
              trailing: Switch(
                value: currentLocale.languageCode == 'ne',
                onChanged: (value) {
                  final newLocale = value ? const Locale('ne') : const Locale('en');
                  ref.read(localeProvider.notifier).state = newLocale;
                  saveLocale(newLocale);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                currentThemeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              ),
              title: Text(l10n.darkMode),
              subtitle: Text(
                currentThemeMode == ThemeMode.dark ? l10n.on : l10n.off,
              ),
              trailing: Switch(
                value: currentThemeMode == ThemeMode.dark,
                onChanged: (value) {
                  final newMode = value ? ThemeMode.dark : ThemeMode.light;
                  ref.read(themeModeProvider.notifier).state = newMode;
                  saveThemeMode(newMode);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                l10n.logout,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.logout),
                    content: Text(l10n.confirmLogout),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref.read(authProvider.notifier).logout();
                        },
                        child: Text(
                          l10n.logout,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
