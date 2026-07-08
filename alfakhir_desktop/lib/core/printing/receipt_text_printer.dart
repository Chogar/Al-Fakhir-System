import 'dart:convert';

import '../../data/models/order_model.dart';
import 'receipt_ticket_text.dart';
import 'receipt_win32_printer.dart';

/// Impression texte ESC/POS (fallback si le flux binaire ticket échoue).
Future<bool> printOrderReceiptAsText({
  required OrderDetailDto order,
  required String restaurantName,
  required String printerName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  final body = buildReceiptTicketText(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
  );
  final encoded = latin1.encode(body);
  final bytes = <int>[
    0x1B,
    0x40,
    ...encoded,
    0x0A,
    0x0A,
    0x1D,
    0x56,
    0x00,
  ];
  return sendRawToWindowsPrinter(printerName, bytes);
}
