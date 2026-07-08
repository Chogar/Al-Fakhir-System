import 'dart:async';

import 'receipt_printer_config.dart';

/// Prépare l'imprimante une fois pour des ventes rapides.
final class ReceiptPrinterCache {
  ReceiptPrinterCache._();

  static String? _printer;
  static CashDrawerKickParams? _kick;
  static Future<void>? _warming;

  static String? get printer => _printer;
  static CashDrawerKickParams? get kick => _kick;

  static Future<void> warmUp() {
    return _warming ??= _doWarmUp();
  }

  static Future<String?> printerOrResolve() async {
    if (_printer != null && _printer!.isNotEmpty) return _printer;
    await warmUp();
    return _printer;
  }

  static Future<CashDrawerKickParams> kickOrLoad() async {
    if (_kick != null) return _kick!;
    await warmUp();
    return _kick ?? const CashDrawerKickParams(pin: 0);
  }

  static Future<void> _doWarmUp() async {
    _printer = await ReceiptPrinterConfig.resolvePrinterFast();
    _kick = await ReceiptPrinterConfig.cashDrawerKickParams();
    unawaited(_resolvePrinterInBackground());
  }

  static Future<void> _resolvePrinterInBackground() async {
    final full = await ReceiptPrinterConfig.resolvePrinterFull();
    if (full != null && full.isNotEmpty) {
      _printer = full;
    }
  }
}
