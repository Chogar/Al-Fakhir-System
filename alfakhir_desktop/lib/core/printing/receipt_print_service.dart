import 'dart:typed_data';

import '../../data/models/order_model.dart';
import 'receipt_escpos_printer.dart';
import 'receipt_pdf.dart';
import 'receipt_printer_config.dart';
import 'receipt_text_printer.dart';

enum ReceiptPrintOutcome { printed, cancelled, failed }

Future<ReceiptPrintOutcome> dispatchReceiptPrint({
  required Uint8List pdfBytes,
  required String jobName,
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  bool interactive = false,
}) async {
  final _ = pdfBytes;
  final __ = jobName;
  final ___ = interactive;
  final printerName = await ReceiptPrinterConfig.resolveThermalPrinterName();

  final escOk = await printOrderReceiptEscPos(
    order: order,
    restaurantName: restaurantName,
    printerName: printerName,
    arabic: arabic,
  );
  if (escOk) return ReceiptPrintOutcome.printed;

  if (printerName != null && printerName.isNotEmpty) {
    final textOk = await printOrderReceiptAsText(
      order: order,
      restaurantName: restaurantName,
      printerName: printerName,
      arabic: arabic,
    );
    if (textOk) return ReceiptPrintOutcome.printed;
  }

  return ReceiptPrintOutcome.failed;
}

Future<ReceiptPrintOutcome> printOrderReceipt({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  final pdf = await exportOrderReceiptPdf(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
  );
  return dispatchReceiptPrint(
    pdfBytes: pdf.bytes,
    jobName: 'Ticket ${order.orderNumber}',
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    interactive: false,
  );
}
