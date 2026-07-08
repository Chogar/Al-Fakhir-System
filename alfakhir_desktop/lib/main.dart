import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api/api_client.dart';
import 'core/locale/app_locale_scope.dart';
import 'core/locale/locale_controller.dart';
import 'core/session/auth_session_store.dart';
import 'core/printing/receipt_arabic_line_escpos.dart';
import 'core/printing/receipt_printer_cache.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSessionStore.load();
  await localeController.load();
  runApp(const AlFakhirApp());
  unawaited(Future.wait([
    ReceiptPrinterCache.warmUp(),
    ReceiptArabicLineEscpos.preload(),
  ]));
}

class AlFakhirApp extends StatelessWidget {
  const AlFakhirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return AppLocaleScope(
          notifier: localeController,
          child: MaterialApp(
            title: 'Restaurant Al-Fakhir',
            theme: AppTheme.light(localeController.isArabic),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => Directionality(
              textDirection: TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const _Bootstrap(),
          ),
        );
      },
    );
  }
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final token = AuthSessionStore.token;
    final user = AuthSessionStore.user;
    if (token != null && user != null) {
      return MainShellScreen(api: ApiClient(), user: user);
    }
    return const LoginScreen();
  }
}
