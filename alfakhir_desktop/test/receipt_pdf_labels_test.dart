import 'package:flutter_test/flutter_test.dart';

import 'package:alfakhir_desktop/core/printing/receipt_pdf.dart';

void main() {
  test('ReceiptPdfLabels FR — statut payée', () {
    final L = ReceiptPdfLabels.french();
    expect(L.orderStatus('PAID'), 'Payée');
    expect(L.paymentMethod('CASH'), 'Espèces');
    expect(
      L.customerFooter,
      contains('Merci d\'avoir choisi Restaurant Al-Fakhir'),
    );
    expect(L.customerFooter, contains('Bon appétit'));
  });

  test('ReceiptPdfLabels AR — statut payée', () {
    final L = ReceiptPdfLabels.arabic();
    expect(L.orderStatus('PAID'), 'مدفوعة');
    expect(L.paymentMethod('CASH'), 'نقداً');
  });
}
