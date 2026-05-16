import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alfakhir_desktop/core/api/api_client.dart';
import 'package:alfakhir_desktop/core/theme/app_theme.dart';
import 'package:alfakhir_desktop/features/auth/login_screen.dart';
import 'package:alfakhir_desktop/l10n/app_strings.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Écran connexion : titre app + bouton Se connecter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAlFakhirTheme(),
        locale: const Locale('fr'),
        home: AppStrings(
          locale: const Locale('fr'),
          child: LoginScreen(
            api: ApiClient(),
            onSuccess: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Al-Fakhir'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
