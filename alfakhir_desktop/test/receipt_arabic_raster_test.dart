import 'package:alfakhir_desktop/core/printing/receipt_arabic_line_escpos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ReceiptArabic précharge et rasterise du texte arabe', () async {
    await ReceiptArabicLineEscpos.preload();
    final bytes = await ReceiptArabicLineEscpos.encodeLine('شاي');
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(20));
  });
}
