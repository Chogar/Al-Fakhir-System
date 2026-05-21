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
  final pin = await ReceiptPrinterConfig.cashDrawerPin();
  final bytes = buildEscPosTicketBytes(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    openCashDrawer: openCashDrawer,
    cashDrawerPin: pin,
  );
  return sendRawToWindowsPrinter(name, bytes);
}

/// Ouvre le tiroir sans imprimer (secours si l'impression a échoué).
Future<bool> openCashDrawer({String? printerName}) async {
  final name = (printerName?.trim().isNotEmpty ?? false)
      ? printerName!.trim()
      : await ReceiptPrinterConfig.resolveThermalPrinterName();
  if (name == null || name.isEmpty) return false;
  final pin = await ReceiptPrinterConfig.cashDrawerPin();
  return sendRawToWindowsPrinter(name, buildCashDrawerKickBytes(pin: pin));
}
