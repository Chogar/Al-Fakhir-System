import 'dart:typed_data';

import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import 'order_receipt_enricher.dart';
import 'receipt_escpos_printer.dart';
import 'receipt_printer_cache.dart';
import 'receipt_printer_config.dart';
import 'receipt_text_printer.dart';

enum ReceiptPrintOutcome { printed, failed }

final class ReceiptPrintResult {
  const ReceiptPrintResult({
    required this.outcome,
    required this.drawerOk,
  });

  final ReceiptPrintOutcome outcome;
  final bool drawerOk;
}

Future<ReceiptPrintResult> dispatchReceiptPrint({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
  Uint8List? prebuiltTicketBytes,
}) async {
  final printerName = await ReceiptPrinterCache.printerOrResolve();
  if (printerName == null || printerName.isEmpty) {
    return const ReceiptPrintResult(
      outcome: ReceiptPrintOutcome.failed,
      drawerOk: false,
    );
  }

  final esc = await printOrderReceiptEscPos(
    order: order,
    restaurantName: restaurantName,
    printerName: printerName,
    arabic: arabic,
    openCashDrawer: true,
    discountFcfa: discountFcfa,
    prebuiltTicketBytes: prebuiltTicketBytes,
  );
  if (esc.printed) {
    return ReceiptPrintResult(
      outcome: ReceiptPrintOutcome.printed,
      drawerOk: esc.drawerOk,
    );
  }

  final textOk = await printOrderReceiptAsText(
    order: order,
    restaurantName: restaurantName,
    printerName: printerName,
    arabic: arabic,
    discountFcfa: discountFcfa,
  );
  if (textOk) {
    scheduleCashDrawerKick(printerName: printerName);
    return const ReceiptPrintResult(
      outcome: ReceiptPrintOutcome.printed,
      drawerOk: true,
    );
  }

  scheduleCashDrawerKick(printerName: printerName);
  return const ReceiptPrintResult(
    outcome: ReceiptPrintOutcome.failed,
    drawerOk: true,
  );
}

/// Imprime le ticket et ouvre le tiroir GF-405 après encaissement.
Future<ReceiptPrintResult> printOrderReceipt({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
  List<ProductDto>? productCatalog,
  Uint8List? prebuiltTicketBytes,
}) async {
  final forReceipt =
      enrichOrderForReceipt(order, catalog: productCatalog ?? const []);
  return dispatchReceiptPrint(
    order: forReceipt,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
    prebuiltTicketBytes: prebuiltTicketBytes,
  );
}

/// Dernière tentative d'ouverture tiroir (après échec impression).
Future<bool> retryCashDrawerAfterSale({String? printerName}) =>
    openCashDrawerReliable(printerName: printerName);
