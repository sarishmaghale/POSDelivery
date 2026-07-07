import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

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
                  ref.read(localeProvider.notifier).state =
                      value ? const Locale('ne') : const Locale('en');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
