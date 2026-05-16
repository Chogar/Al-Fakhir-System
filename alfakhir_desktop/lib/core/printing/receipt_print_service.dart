import '../../data/models/order_model.dart';
import 'receipt_escpos_builder.dart' show EscPosCodePage, buildEscPosTicketBytes;
import 'receipt_printer_config.dart';
import 'receipt_win32_printer.dart';

/// Résultat de l'impression d'un ticket.
enum ReceiptPrintOutcome {
  printed,
  cancelled,
  failed,
}

String? _cachedPrinterName;

/// Impression rapide XP-58C (API Windows native, une seule tentative).
Future<ReceiptPrintOutcome> printThermalReceipt({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  final printerName =
      _cachedPrinterName ?? await ReceiptPrinterConfig.resolveThermalPrinterName();
  if (printerName == null || printerName.isEmpty) {
    throw Exception(
      'Imprimante XP-58C introuvable. Executez : '
      'install\\scripts\\set_receipt_printer.ps1 -PrinterName "XP-58C"',
    );
  }
  _cachedPrinterName = printerName;

  if (ReceiptPrinterConfig.isVirtualPrinter(printerName)) {
    throw Exception('Utilisez XP-58C, pas une imprimante PDF virtuelle.');
  }

  final bytes = buildEscPosTicketBytes(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
    codePage: arabic
        ? EscPosCodePage.cp437
        : EscPosCodePage.windows1252,
  );

  final ok = sendRawToWindowsPrinter(printerName, bytes);
  if (ok) return ReceiptPrintOutcome.printed;

  throw Exception(
    'Impression echouee sur « $printerName ». '
    'Verifiez : imprimante allumee, USB branche, pilote XP-58C, papier thermique.',
  );
}
