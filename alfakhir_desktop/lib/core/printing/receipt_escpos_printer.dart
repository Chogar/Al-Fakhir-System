import '../../data/models/order_model.dart';
import 'receipt_escpos_builder.dart';
import 'receipt_printer_config.dart';
import 'receipt_win32_printer.dart';

Future<bool> printOrderReceiptEscPos({
  required OrderDetailDto order,
  required String restaurantName,
  String? printerName,
  bool arabic = false,
}) async {
  final name = (printerName?.trim().isNotEmpty ?? false)
      ? printerName!.trim()
      : await ReceiptPrinterConfig.resolveThermalPrinterName();
  if (name == null || name.isEmpty) return false;
  final bytes = buildEscPosTicketBytes(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
  );
  return sendRawToWindowsPrinter(name, bytes);
}
