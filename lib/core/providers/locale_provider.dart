import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _localeKey = 'app_locale';

final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('en');
});

Future<Locale> loadSavedLocale() async {
  const storage = FlutterSecureStorage();
  final code = await storage.read(key: _localeKey);
  if (code == 'ne') return const Locale('ne');
  return const Locale('en');
}

Future<void> saveLocale(Locale locale) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: _localeKey, value: locale.languageCode);
}
