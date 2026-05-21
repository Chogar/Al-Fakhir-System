import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/order_model.dart';
import 'receipt_ticket_text.dart';

enum EscPosCodePage {
  cp437(0),
  windows1252(16);

  const EscPosCodePage(this.escTValue);
  final int escTValue;
}

/// Pulse tiroir-caisse (RJ11 sur imprimante) — ESC p m t1 t2.
Uint8List buildCashDrawerKickBytes({int pin = 0}) {
  final m = pin.clamp(0, 1);
  return Uint8List.fromList([0x1B, 0x70, m, 0x19, 0xFA]);
}

Uint8List buildEscPosTicketBytes({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  EscPosCodePage codePage = EscPosCodePage.windows1252,
  bool openCashDrawer = true,
  int cashDrawerPin = 0,
}) {
  final body = buildReceiptTicketText(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
  );
  final out = <int>[0x1B, 0x40, 0x1B, 0x74, codePage.escTValue];
  out.addAll(_encode(body, codePage));
  out.addAll([0x0A, 0x0A, 0x0A, 0x1D, 0x56, 0x00]);
  if (openCashDrawer) {
    out.addAll(buildCashDrawerKickBytes(pin: cashDrawerPin));
  }
  return Uint8List.fromList(out);
}

List<int> _encode(String text, EscPosCodePage cp) {
  switch (cp) {
    case EscPosCodePage.windows1252:
      return Encoding.getByName('windows-1252')?.encode(text) ??
          latin1.encode(text);
    case EscPosCodePage.cp437:
      return latin1.encode(text);
  }
}
