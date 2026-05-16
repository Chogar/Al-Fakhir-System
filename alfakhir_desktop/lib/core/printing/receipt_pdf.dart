import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../branding/app_branding.dart';
import '../../data/models/order_model.dart';
import 'receipt_print_service.dart';
import 'receipt_printer_config.dart';

/// Libellés ticket PDF (évite la dépendance à Flutter dans ce module).
class ReceiptPdfLabels {
  const ReceiptPdfLabels._(this.ar);
  final bool ar;

  factory ReceiptPdfLabels.arabic() => const ReceiptPdfLabels._(true);
  factory ReceiptPdfLabels.french() => const ReceiptPdfLabels._(false);

  String receiptNo(int orderNumber) =>
      ar ? 'إيصال رقم $orderNumber' : 'Reçu n°$orderNumber';

  String get date => ar ? 'التاريخ' : 'Date';
  String get service => ar ? 'الخدمة' : 'Service';
  String get table => ar ? 'طاولة' : 'Table';
  String get client => ar ? 'العميل' : 'Client';
  String get status => ar ? 'الحالة' : 'Statut';
  String get colArticle => ar ? 'الصنف' : 'Article';
  String get colQty => ar ? 'الكمية' : 'Qté';
  String get colTotal => ar ? 'المجموع' : 'Total';
  String get subtotal => ar ? 'المجموع الفرعي' : 'Sous-total';
  String get discount =>
      ar ? 'تخفيض على المجموع' : 'Réduction sur le montant total';
  String get total => ar ? 'المجموع' : 'Total';
  String get paid => ar ? 'المدفوع' : 'Payé';
  String get due => ar ? 'المتبقي' : 'Reste';
  String get payments => ar ? 'المدفوعات' : 'Paiements';
  String get thanks => customerFooter;

  /// Message de remerciement affiché en bas du ticket pour le client.
  String get customerFooter => ar
      ? 'شكراً لاختياركم مطعم الفاخر\nبالهناء والشفاء !'
      : 'Merci d\'avoir choisi Restaurant Al-Fakhir\nBonne appétit !';
  String noteLine(String notes) =>
      ar ? 'ملاحظة : $notes' : 'Note : $notes';

  String serviceType(String code) {
    if (!ar) {
      return switch (code) {
        'DINE_IN' => 'Sur place',
        'TAKEAWAY' => 'À emporter',
        'DELIVERY' => 'Livraison',
        _ => code,
      };
    }
    return switch (code) {
      'DINE_IN' => 'داخل الصالة',
      'TAKEAWAY' => 'سفري',
      'DELIVERY' => 'توصيل',
      _ => code,
    };
  }

  String orderStatus(String code) {
    if (!ar) {
      return switch (code) {
        'PLACED' => 'Enregistrée',
        'PREPARING' => 'En préparation',
        'READY' => 'Prête',
        'SERVED' => 'Servie',
        'PAID' => 'Payée',
        'CANCELLED' => 'Annulée',
        _ => code,
      };
    }
    return switch (code) {
      'PLACED' => 'مسجلة',
      'PREPARING' => 'قيد التحضير',
      'READY' => 'جاهزة',
      'SERVED' => 'مقدمة',
      'PAID' => 'مدفوعة',
      'CANCELLED' => 'ملغاة',
      _ => code,
    };
  }

  String paymentMethod(String code) {
    if (!ar) {
      return switch (code) {
        'CASH' => 'Espèces',
        'MOBILE_MONEY' => 'Mobile money',
        'BANK_CARD' => 'Carte bancaire',
        _ => code,
      };
    }
    return switch (code) {
      'CASH' => 'نقداً',
      'MOBILE_MONEY' => 'محفظة إلكترونية',
      'BANK_CARD' => 'بطاقة',
      _ => code,
    };
  }
}

/// Impression ticket thermique (toujours en français sur l'imprimante POS).
Future<ReceiptPrintOutcome> printOrderReceipt({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  return printThermalReceipt(
    order: order,
    restaurantName: restaurantName,
    arabic: false,
    discountFcfa: discountFcfa,
  );
}

/// Export PDF du ticket (aperçu / archivage uniquement).
Future<ReceiptPrintOutcome> exportOrderReceiptPdf({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  final L = arabic ? ReceiptPdfLabels.arabic() : ReceiptPdfLabels.french();
  final subtotal =
      double.tryParse(order.totals.subtotal.replaceAll(',', '.')) ?? 0;
  final discount = discountFcfa.clamp(0, subtotal);
  final total = subtotal - discount;

  final pw.Font base;
  final pw.Font bold;
  if (arabic) {
    base = await PdfGoogleFonts.notoSansArabicRegular();
    bold = await PdfGoogleFonts.notoSansArabicBold();
  } else {
    base = await PdfGoogleFonts.openSansRegular();
    bold = await PdfGoogleFonts.openSansBold();
  }

  Uint8List? logoBytes;
  try {
    final data = await rootBundle.load(AppBranding.logoAsset);
    logoBytes = data.buffer.asUint8List();
  } catch (_) {
    logoBytes = null;
  }

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: base, bold: bold),
  );

  final ticketFormat = PdfPageFormat(
    kReceiptPaperWidthMm * PdfPageFormat.mm,
    280 * PdfPageFormat.mm,
    marginAll: 2 * PdfPageFormat.mm,
  );

  String fmtAmount(String raw) {
    final n = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
    if (n == n.roundToDouble()) {
      return n.toStringAsFixed(0);
    }
    return n.toStringAsFixed(2);
  }

  String fmtDate(String iso) {
    if (iso.length < 16) return iso;
    return iso.substring(0, 16).replaceFirst('T', ' ');
  }

  doc.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: ticketFormat,
        textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (logoBytes != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 44,
                  height: 44,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 4),
            ],
            pw.Center(
              child: pw.Text(
                restaurantName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                L.receiptNo(order.orderNumber),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${L.date} :', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  fmtDate(order.createdAt),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${L.service} :',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  L.serviceType(order.serviceType),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
            if (order.diningTable != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${L.table} :',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    '${order.diningTable!.number}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            if (order.customer != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${L.client} :',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    order.customer!.name,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.5),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    L.colArticle,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    L.colQty,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    L.colTotal,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.end,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            for (final line in order.items)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        line.displayNameLocalized(arabic),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        '${line.quantity}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        fmtAmount(
                          ((double.tryParse(
                                        line.unitPrice.replaceAll(',', '.')) ??
                                    0) *
                                line.quantity)
                            .toString(),
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(L.subtotal, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '${fmtAmount(order.totals.subtotal)} FCFA',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            if (discount > 0.009) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(L.discount, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '-${fmtAmount(discount.toString())} FCFA',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  L.total,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${fmtAmount(total.toString())} FCFA',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.Center(
              child: pw.Text(
                L.customerFooter,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if ((order.notes ?? '').isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                L.noteLine(order.notes!),
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  final pdfBytes = await doc.save();
  final jobName = 'recu_${order.orderNumber}';

  final ok = await Printing.layoutPdf(
    onLayout: (_) async => pdfBytes,
    name: jobName,
    format: ticketFormat,
    dynamicLayout: true,
  );
  return ok == true
      ? ReceiptPrintOutcome.printed
      : ReceiptPrintOutcome.cancelled;
}
