import 'package:flutter_test/flutter_test.dart';

void main() {
  test('indices XP-58 reconnaissent le nom Windows', () {
    const hints = ['xp-58iit', 'xp-58', 'xprinter'];
    expect(_matches('XP-58', hints), isTrue);
    expect(_matches('XPrinter XP-58IIT', hints), isTrue);
    expect(_matches('HP LaserJet', hints), isFalse);
  });
}

bool _matches(String printerName, List<String> hints) {
  final lower = printerName.toLowerCase();
  for (final hint in hints) {
    if (lower.contains(hint.toLowerCase())) return true;
  }
  return false;
}
