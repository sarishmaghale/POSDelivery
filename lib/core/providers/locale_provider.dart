import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('en');
});

final localeServiceProvider = Provider<LocaleService>((ref) {
  return LocaleService(ref);
});

class LocaleService {
  final Ref _ref;
  LocaleService(this._ref);

  void setLocale(Locale locale) {
    _ref.read(localeProvider.notifier).state = locale;
  }

  Locale get locale => _ref.read(localeProvider);
}
