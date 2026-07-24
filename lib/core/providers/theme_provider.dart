import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeModeKey = 'app_theme_mode';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});

Future<ThemeMode> loadSavedThemeMode() async {
  const storage = FlutterSecureStorage();
  final value = await storage.read(key: _themeModeKey);
  if (value == 'dark') return ThemeMode.dark;
  if (value == 'system') return ThemeMode.system;
  return ThemeMode.light;
}

Future<void> saveThemeMode(ThemeMode mode) async {
  const storage = FlutterSecureStorage();
  String value;
  switch (mode) {
    case ThemeMode.dark:
      value = 'dark';
    case ThemeMode.system:
      value = 'system';
    default:
      value = 'light';
  }
  await storage.write(key: _themeModeKey, value: value);
}
