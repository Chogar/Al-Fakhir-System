import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale_code';

/// Langue UI persistée (FR / AR) pour le bouton de traduction.
Future<Locale> loadSavedLocale() async {
  try {
    final p = await SharedPreferences.getInstance()
        .timeout(const Duration(seconds: 3));
    final code = p.getString(_kLocaleKey);
    if (code == 'ar') return const Locale('ar');
  } catch (_) {}
  return const Locale('fr');
}

Future<void> saveLocale(Locale locale) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kLocaleKey, locale.languageCode);
}
