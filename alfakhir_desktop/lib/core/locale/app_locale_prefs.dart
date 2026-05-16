import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale_code';

Future<Locale> loadSavedLocale() async {
  final p = await SharedPreferences.getInstance();
  final code = p.getString(_kLocaleKey);
  if (code == 'ar') return const Locale('ar');
  return const Locale('fr');
}

Future<void> saveLocale(Locale locale) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kLocaleKey, locale.languageCode);
}
