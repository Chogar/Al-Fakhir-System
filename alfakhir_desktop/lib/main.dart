import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api/api_client.dart';
import 'core/auth/saved_login_credentials.dart';
import 'core/locale/app_locale_prefs.dart';
import 'core/navigation/app_navigator.dart';
import 'core/session/auth_session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell_screen.dart';
import 'l10n/app_strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionStore = AuthSessionStore();
  await sessionStore.clear();
  final api = ApiClient();
  final initialLocale = await loadSavedLocale();
  runApp(AlFakhirApp(
    api: api,
    sessionStore: sessionStore,
    initialLocale: initialLocale,
  ));
}

class AlFakhirApp extends StatefulWidget {
  const AlFakhirApp({
    super.key,
    required this.api,
    required this.sessionStore,
    required this.initialLocale,
  });

  final ApiClient api;
  final AuthSessionStore sessionStore;
  final Locale initialLocale;

  @override
  State<AlFakhirApp> createState() => _AlFakhirAppState();
}

class _AlFakhirAppState extends State<AlFakhirApp> {
  Map<String, dynamic>? _user;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    widget.api.setOnUnauthorized(() async {
      await widget.sessionStore.clear();
      if (mounted) setState(() => _user = null);
    });
  }

  @override
  void dispose() {
    widget.api.setOnUnauthorized(null);
    super.dispose();
  }

  Future<void> _onLoginSuccess(Map<String, dynamic>? user) async {
    final token = widget.api.accessToken;
    if (token != null && token.isNotEmpty) {
      await widget.sessionStore.save(token, user ?? {});
    }
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    await SavedLoginCredentials.skipNextAutoLogin();
    widget.api.setAccessToken(null);
    await widget.sessionStore.clear();
    if (mounted) setState(() => _user = null);
  }

  Future<void> _setLocale(Locale locale) async {
    setState(() => _locale = locale);
    await saveLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _locale.languageCode == 'ar';

    return MaterialApp(
      navigatorKey: AppNavigator.key,
      title: isAr
          ? 'نظام إدارة مطعم الفاخر'
          : 'Al-Fakhir Restaurant Management System',
      theme: buildAlFakhirTheme(),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return AppStrings(
          locale: _locale,
          child: Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: _user == null
          ? LoginScreen(
              api: widget.api,
              onSuccess: _onLoginSuccess,
            )
          : MainShellScreen(
              api: widget.api,
              user: _user,
              onLogout: _logout,
              onLocaleChanged: _setLocale,
            ),
    );
  }
}
