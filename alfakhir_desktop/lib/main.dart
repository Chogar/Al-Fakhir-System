import 'package:flutter/material.dart';

import 'core/session/auth_session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell_screen.dart';
import 'core/api/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSessionStore.load();
  runApp(const AlFakhirApp());
}

class AlFakhirApp extends StatelessWidget {
  const AlFakhirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Al-Fakhir',
      theme: AppTheme.light(),
      locale: const Locale('fr'),
      home: const _Bootstrap(),
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
