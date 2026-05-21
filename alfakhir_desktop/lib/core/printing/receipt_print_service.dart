import '../../data/models/order_model.dart';
import 'receipt_escpos_builder.dart';
import 'receipt_escpos_printer.dart';
import 'receipt_printer_config.dart';
import 'receipt_win32_printer.dart';

enum ReceiptPrintOutcome { printed, cancelled, failed }

String? _cachedPrinterName;

/// Impression ticket thermique XP-58 (design complet + tiroir).
Future<ReceiptPrintOutcome> printThermalReceipt({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  final printerName =
      _cachedPrinterName ?? await ReceiptPrinterConfig.resolveThermalPrinterName();
  if (printerName == null || printerName.isEmpty) {
    return ReceiptPrintOutcome.failed;
  }
  _cachedPrinterName = printerName;

  if (ReceiptPrinterConfig.isVirtualPrinter(printerName)) {
    return ReceiptPrintOutcome.failed;
  }

  final bytes = buildEscPosTicketBytes(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
    openCashDrawer: true,
  );

  final ok = sendRawToWindowsPrinter(printerName, bytes);
  return ok ? ReceiptPrintOutcome.printed : ReceiptPrintOutcome.failed;
}

Future<ReceiptPrintOutcome> printOrderReceipt({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  return printThermalReceipt(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
  );
}

/// Ouvre le tiroir (commande séparée, les deux broches RJ11).
Future<bool> openCashDrawerAfterSale() async {
  final printerName =
      _cachedPrinterName ?? await ReceiptPrinterConfig.resolveThermalPrinterName();
  if (printerName == null || printerName.isEmpty) return false;
  return sendRawToWindowsPrinter(printerName, buildCashDrawerKickBytes());
}
