import 'dart:typed_data';

import '../../data/models/order_model.dart';
import 'receipt_arabic_line_escpos.dart';
import 'receipt_printer_config.dart';
import 'receipt_ticket_text.dart';

enum EscPosCodePage {
  cp437(0),
  windows1252(16);

  const EscPosCodePage(this.escTValue);
  final int escTValue;
}

/// Impulsion standard GF-405 / XP-58 : ESC p 0 25 250 (broche 0, ~50 ms ON, ~500 ms OFF).
Uint8List buildGf405StandardDrawerKickBytes() {
  return Uint8List.fromList([0x1B, 0x70, 0, 25, 250]);
}

/// Pulse tiroir RJ11 (ESC p). Durées en ms, converties en unités de 2 ms.
Uint8List buildCashDrawerKickBytes({
  bool bothPins = false,
  int pin = 0,
  int onMs = 50,
  int offMs = 500,
}) {
  final t1 = (onMs ~/ 2).clamp(1, 255);
  final t2 = (offMs ~/ 2).clamp(1, 255);
  void addKick(List<int> out, int m) {
    out.addAll([0x1B, 0x70, m, t1, t2]);
  }

  final out = <int>[];
  if (bothPins) {
    addKick(out, 0);
    addKick(out, 1);
  } else {
    addKick(out, pin.clamp(0, 1));
  }
  return Uint8List.fromList(out);
}

/// Job RAW identique à `test_drawer_gf405.ps1 -BothPins` (150 ms ON, 600 ms OFF).
Uint8List buildGf405ScriptMatchedDrawerJobBytes({bool bothPins = true, int pin = 0}) {
  final out = <int>[0x1B, 0x40];
  void addKick(int m) {
    out.addAll(buildCashDrawerKickBytes(
      bothPins: false,
      pin: m,
      onMs: 150,
      offMs: 600,
    ));
  }

  if (bothPins) {
    addKick(0);
    addKick(0);
    addKick(1);
    addKick(1);
  } else {
    addKick(pin);
    addKick(pin);
  }
  return Uint8List.fromList(out);
}

/// Job RAW dédié au tiroir (init + double impulsion), séparé du ticket.
Uint8List buildDedicatedDrawerJobBytes(CashDrawerKickParams kick) {
  final out = <int>[0x1B, 0x40];
  final pulse = buildCashDrawerKickBytes(
    bothPins: kick.bothPins,
    pin: kick.pin,
    onMs: kick.onMs,
    offMs: kick.offMs,
  );
  out.addAll(pulse);
  out.addAll(pulse);
  return Uint8List.fromList(out);
}

Future<Uint8List> buildEscPosTicketBytes({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  EscPosCodePage codePage = EscPosCodePage.windows1252,
  bool openCashDrawer = true,
  CashDrawerKickParams? drawerKick,
  double discountFcfa = 0,
}) async {
  final kick = drawerKick ??
      const CashDrawerKickParams(pin: 0, onMs: 100, offMs: 500);
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
    drawerKick: kick,
    emphasizeFirstLine: true,
  );
}

Future<Uint8List> _buildEscPosFromText(
  String text, {
  required EscPosCodePage codePage,
  required bool cutPaper,
  bool openCashDrawer = false,
  bool drawerKickAtStart = false,
  CashDrawerKickParams drawerKick = const CashDrawerKickParams(pin: 0),
  bool emphasizeFirstLine = false,
}) async {
  final out = <int>[];
  void appendDrawerPulse() {
    out.addAll(
      buildCashDrawerKickBytes(
        bothPins: drawerKick.bothPins,
        pin: drawerKick.pin,
        onMs: drawerKick.onMs,
        offMs: drawerKick.offMs,
      ),
    );
  }

  out.addAll([0x1B, 0x40]);
  if (openCashDrawer && drawerKickAtStart) {
    appendDrawerPulse();
    appendDrawerPulse();
  }
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
    out.addAll(await encodeReceiptLineWithOptionalRaster(line));
    if (emphasizeFirstLine && i == 0) {
      out.addAll([0x1B, 0x21, 0x00]);
    }
    out.addAll([0x0D, 0x0A]);
  }

  out.addAll([0x1B, 0x64, 0x04]);
  if (openCashDrawer) {
    // Fin de ticket : ESC p 0 25 250 (GF-405) dans le même flux que l'impression.
    out.addAll(buildGf405StandardDrawerKickBytes());
    out.addAll(buildGf405StandardDrawerKickBytes());
  }
  if (cutPaper) {
    out.addAll([0x1D, 0x56, 0x00]);
  }
  return Uint8List.fromList(out);
}
