import '../../data/models/order_model.dart';
import 'receipt_escpos_builder.dart';
import 'receipt_printer_config.dart';
import 'receipt_win32_printer.dart';

Future<bool> printOrderReceiptEscPos({
  required OrderDetailDto order,
  required String restaurantName,
  String? printerName,
  bool arabic = false,
  bool openCashDrawer = true,
}) async {
  final name = (printerName?.trim().isNotEmpty ?? false)
      ? printerName!.trim()
      : await ReceiptPrinterConfig.resolveThermalPrinterName();
  if (name == null || name.isEmpty) return false;
  if (ReceiptPrinterConfig.isVirtualPrinter(name)) return false;

  if (openCashDrawer) {
    await openCashDrawerKick(printerName: name);
  }

  final kick = await ReceiptPrinterConfig.cashDrawerKickParams();
  final bytes = buildEscPosTicketBytes(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    openCashDrawer: openCashDrawer,
    drawerKick: kick,
  );
  return sendRawToWindowsPrinter(name, bytes);
}

/// Ouvre le tiroir GF-405 (RJ11) via un job RAW dédié.
Future<bool> openCashDrawerKick({String? printerName}) async {
  final name = (printerName?.trim().isNotEmpty ?? false)
      ? printerName!.trim()
      : await ReceiptPrinterConfig.resolveThermalPrinterName();
  if (name == null || name.isEmpty) return false;
  if (ReceiptPrinterConfig.isVirtualPrinter(name)) return false;

  final kick = await ReceiptPrinterConfig.cashDrawerKickParams();
  final pulse = buildCashDrawerKickBytes(
    bothPins: kick.bothPins,
    pin: kick.pin,
    onMs: kick.onMs,
    offMs: kick.offMs,
  );
  if (sendRawToWindowsPrinter(name, pulse)) return true;

  if (kick.bothPins) return false;
  return sendRawToWindowsPrinter(
    name,
    buildCashDrawerKickBytes(
      bothPins: true,
      pin: kick.pin,
      onMs: kick.onMs,
      offMs: kick.offMs,
    ),
  );
}
