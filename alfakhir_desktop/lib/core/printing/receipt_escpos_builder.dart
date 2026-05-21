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

/// Pulse tiroir-caisse RJ11 (broches 0 et 1 pour compatibilité XP-58).
Uint8List buildCashDrawerKickBytes({bool bothPins = true, int pin = 0}) {
  if (bothPins) {
    return Uint8List.fromList([
      0x1B, 0x70, 0x00, 0x32, 0xC8,
      0x1B, 0x70, 0x01, 0x32, 0xC8,
    ]);
  }
  final m = pin.clamp(0, 1);
  return Uint8List.fromList([0x1B, 0x70, m, 0x32, 0xC8]);
}

Uint8List buildEscPosTicketBytes({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
  EscPosCodePage codePage = EscPosCodePage.windows1252,
  bool openCashDrawer = true,
}) {
  final body = buildReceiptTicketText(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
  );
  return _buildEscPosFromText(
    body,
    codePage: codePage,
    cutPaper: true,
    openCashDrawer: openCashDrawer,
    emphasizeFirstLine: true,
  );
}

Uint8List _buildEscPosFromText(
  String text, {
  required EscPosCodePage codePage,
  required bool cutPaper,
  bool openCashDrawer = false,
  bool emphasizeFirstLine = false,
}) {
  final out = <int>[];

  out.addAll([0x1B, 0x40]);
  out.addAll([0x1B, 0x32]);
  out.addAll([0x1B, 0x74, codePage.escTValue]);
  out.addAll([0x1B, 0x4D, 0x00]);
  out.addAll([0x1B, 0x21, 0x00]);

  final lines = text.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.isEmpty) {
      out.add(0x0A);
      continue;
    }
    if (emphasizeFirstLine && i == 0) {
      out.addAll([0x1B, 0x21, 0x30]);
    }
    out.addAll(_encodeLine(line, codePage));
    if (emphasizeFirstLine && i == 0) {
      out.addAll([0x1B, 0x21, 0x00]);
    }
    out.addAll([0x0D, 0x0A]);
  }

  out.addAll([0x1B, 0x64, 0x04]);
  if (openCashDrawer) {
    out.addAll(buildCashDrawerKickBytes());
  }
  if (cutPaper) {
    out.addAll([0x1D, 0x56, 0x00]);
  }
  return Uint8List.fromList(out);
}

List<int> _encodeLine(String line, EscPosCodePage codePage) {
  final safe = _latinizeIfNeeded(line);
  switch (codePage) {
    case EscPosCodePage.windows1252:
      return Encoding.getByName('windows-1252')?.encode(safe) ??
          latin1.encode(safe);
    case EscPosCodePage.cp437:
      return latin1.encode(safe);
  }
}

String _latinizeIfNeeded(String input) {
  const map = {
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'à': 'a',
    'ù': 'u',
    'ô': 'o',
    'î': 'i',
    'ç': 'c',
    'É': 'E',
    'À': 'A',
    '’': "'",
    '€': ' EUR',
  };
  final buf = StringBuffer();
  for (final r in input.runes) {
    final ch = String.fromCharCode(r);
    if (ch.codeUnitAt(0) < 128) {
      buf.write(ch);
    } else {
      buf.write(map[ch] ?? '?');
    }
  }
  return buf.toString();
}
