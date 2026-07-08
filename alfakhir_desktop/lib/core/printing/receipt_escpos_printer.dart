import 'dart:io';
import 'dart:typed_data';

import '../../data/models/order_model.dart';
import 'receipt_arabic_line_escpos.dart';
import 'receipt_escpos_builder.dart';
import 'receipt_printer_cache.dart';
import 'receipt_printer_config.dart';
import 'receipt_win32_printer.dart';

// GF-405 : RJ11 sur imprimante XP-58C. Ouverture = ESC/POS RAW ou script test_drawer_gf405.ps1.

const Duration _drawerDelayAfterPrint = Duration(milliseconds: 80);

bool _drawerOperationInProgress = false;

Future<String?> _resolvePrinterName(String? printerName) async {
  final trimmed = printerName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    if (await ReceiptPrinterConfig.printerExistsOnWindows(trimmed)) {
      return trimmed;
    }
  }
  return ReceiptPrinterConfig.resolvePrinterForDrawer();
}

Future<bool> _sendRawDrawerBytes(String printerName, List<int> bytes) {
  return Future.value(sendRawToWindowsPrinter(printerName, bytes));
}

Future<bool> _sendGf405DrawerJob(String printerName, {bool bothPins = true}) {
  return _sendRawDrawerBytes(
    printerName,
    buildGf405ScriptMatchedDrawerJobBytes(bothPins: bothPins),
  );
}

Future<bool> _sendDedicatedDrawerJob(
  String printerName,
  CashDrawerKickParams kick,
) async {
  return _sendRawDrawerBytes(
    printerName,
    buildDedicatedDrawerJobBytes(kick),
  );
}

Future<bool> _openCashDrawerViaPowerShell(
  String printerName, {
  required bool bothPins,
}) async {
  if (!Platform.isWindows) return false;
  final local = Platform.environment['LOCALAPPDATA'];
  final candidates = <String>[
    if (local != null)
      '$local\\Programs\\Al-Fakhir\\scripts\\test_drawer_gf405.ps1',
    r'C:\Users\AL FAKHIR\Documents\Al-Fakhir System\install\scripts\test_drawer_gf405.ps1',
  ];
  for (final script in candidates) {
    if (!File(script).existsSync()) continue;
    final args = <String>[
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script,
      '-PrinterName',
      printerName,
    ];
    if (bothPins) args.add('-BothPins');
    try {
      final result = await Process.run(
        'powershell.exe',
        args,
        runInShell: false,
      );
      final out = '${result.stdout}${result.stderr}'.toLowerCase();
      if (result.exitCode == 0 && out.contains('ok')) return true;
    } catch (_) {}
  }
  return false;
}

Future<T> _withDrawerLock<T>(Future<T> Function() action) async {
  while (_drawerOperationInProgress) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  _drawerOperationInProgress = true;
  try {
    return await action();
  } finally {
    _drawerOperationInProgress = false;
  }
}

/// RAW ESC/POS d'abord (rapide), script PS en secours.
Future<bool> _kickDrawerReliableSequence(
  String name,
  CashDrawerKickParams kick,
) async {
  final bothPins = kick.bothPins;

  if (await _sendGf405DrawerJob(name, bothPins: bothPins)) {
    return true;
  }

  if (await _sendDedicatedDrawerJob(
    name,
    CashDrawerKickParams(
      pin: kick.pin,
      onMs: kick.onMs < 150 ? 150 : kick.onMs,
      offMs: kick.offMs < 600 ? 600 : kick.offMs,
      bothPins: true,
    ),
  )) {
    return true;
  }

  return _openCashDrawerViaPowerShell(name, bothPins: bothPins);
}

Future<bool> openCashDrawerReliable({String? printerName}) async {
  final name = await _resolvePrinterName(printerName);
  if (name == null || name.isEmpty) return false;
  if (ReceiptPrinterConfig.isVirtualPrinter(name)) return false;

  return _withDrawerLock(() async {
    final kick = await ReceiptPrinterConfig.cashDrawerKickParams();
    return _kickDrawerReliableSequence(name, kick);
  });
}

/// Ouvre le tiroir en arrière-plan (ne bloque pas l'écran caisse).
void scheduleCashDrawerKick({
  String? printerName,
  CashDrawerKickParams? kick,
}) {
  Future<void>(() async {
    final name = printerName ?? await ReceiptPrinterCache.printerOrResolve();
    if (name == null || name.isEmpty) return;
    if (ReceiptPrinterConfig.isVirtualPrinter(name)) return;
    final params = kick ?? await ReceiptPrinterCache.kickOrLoad();
    await Future<void>.delayed(_drawerDelayAfterPrint);
    await _withDrawerLock(() => _kickDrawerReliableSequence(name, params));
  });
}

/// Après vente manuelle (réessai tiroir).
Future<bool> openCashDrawerAfterSale({
  String? printerName,
  bool ticketJustPrinted = false,
}) async {
  final name = await _resolvePrinterName(printerName);
  if (name == null || name.isEmpty) return false;
  if (ReceiptPrinterConfig.isVirtualPrinter(name)) return false;

  if (ticketJustPrinted) {
    scheduleCashDrawerKick(printerName: name);
    return true;
  }

  return _withDrawerLock(() async {
    final kick = await ReceiptPrinterCache.kickOrLoad();
    return _kickDrawerReliableSequence(name, kick);
  });
}

Future<bool> openCashDrawerKick({String? printerName}) =>
    openCashDrawerReliable(printerName: printerName);

Future<({bool printed, bool drawerOk})> printOrderReceiptEscPos({
  required OrderDetailDto order,
  required String restaurantName,
  String? printerName,
  bool arabic = false,
  bool openCashDrawer = true,
  double discountFcfa = 0,
  Uint8List? prebuiltTicketBytes,
}) async {
  final name =
      printerName ?? await ReceiptPrinterCache.printerOrResolve();
  if (name == null || name.isEmpty) {
    return (printed: false, drawerOk: false);
  }
  if (ReceiptPrinterConfig.isVirtualPrinter(name)) {
    return (printed: false, drawerOk: false);
  }

  final kick = await ReceiptPrinterCache.kickOrLoad();
  await ReceiptArabicLineEscpos.preload();
  final bytes = prebuiltTicketBytes ??
      await buildEscPosTicketBytes(
        order: order,
        restaurantName: restaurantName,
        arabic: arabic,
        openCashDrawer: false,
        drawerKick: kick,
        discountFcfa: discountFcfa,
      );
  final printed = sendRawToWindowsPrinter(name, bytes);

  if (openCashDrawer && printed) {
    scheduleCashDrawerKick(printerName: name, kick: kick);
  }

  return (printed: printed, drawerOk: !openCashDrawer || printed);
}
