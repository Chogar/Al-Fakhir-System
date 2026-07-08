import 'dart:typed_data';

import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import 'order_receipt_enricher.dart';
import 'receipt_arabic_line_escpos.dart';
import 'receipt_escpos_builder.dart';
import 'receipt_printer_cache.dart';
import 'receipt_printer_config.dart';

/// Prépare les octets ESC/POS pendant la fenêtre de validation (remise).
final class ReceiptTicketCache {
  ReceiptTicketCache._();

  static String? _orderId;
  static Uint8List? _bytes;
  static Future<void>? _preparing;

  /// Attend la fin de la préparation lancée par [prepareAsync].
  static Future<void> waitForReady() async {
    final f = _preparing;
    if (f != null) await f;
  }

  static Future<void> prepareAsync({
    required OrderDetailDto order,
    required String restaurantName,
    required bool arabic,
    required List<ProductDto> productCatalog,
    double discountFcfa = 0,
  }) {
    return _preparing ??= _doPrepare(
      order: order,
      restaurantName: restaurantName,
      arabic: arabic,
      productCatalog: productCatalog,
      discountFcfa: discountFcfa,
    );
  }

  static Future<void> _doPrepare({
    required OrderDetailDto order,
    required String restaurantName,
    required bool arabic,
    required List<ProductDto> productCatalog,
    required double discountFcfa,
  }) async {
    try {
      final id = order.id;
      if (id.isEmpty) return;
      _orderId = id;
      await ReceiptArabicLineEscpos.preload();
      final enriched = enrichOrderForReceipt(order, catalog: productCatalog);
      _bytes = await buildEscPosTicketBytes(
        order: enriched,
        restaurantName: restaurantName,
        arabic: arabic,
        openCashDrawer: false,
        drawerKick: ReceiptPrinterCache.kick ?? const CashDrawerKickParams(pin: 0),
        discountFcfa: discountFcfa,
      );
    } finally {
      _preparing = null;
    }
  }

  static Uint8List? takeForOrder(String orderId) {
    if (_orderId != orderId || _bytes == null) return null;
    final out = _bytes;
    _bytes = null;
    _orderId = null;
    return out;
  }

  static void clear() {
    _orderId = null;
    _bytes = null;
    _preparing = null;
  }
}
