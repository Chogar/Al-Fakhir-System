import 'package:flutter_test/flutter_test.dart';

import 'package:alfakhir_desktop/main.dart';

void main() {
  testWidgets('bootstrap renders login screen when no session', (tester) async {
    await tester.pumpWidget(const AlFakhirApp());
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
  });
}
