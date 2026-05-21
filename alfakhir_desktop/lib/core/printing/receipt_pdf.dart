import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/order_model.dart';

class ReceiptPdfLabels {
  ReceiptPdfLabels._({
    required this.date,
    required this.service,
    required this.table,
    required this.client,
    required this.status,
    required this.colArticle,
    required this.colQty,
    required this.colTotal,
    required this.subtotal,
    required this.total,
  });

  final String date;
  final String service;
  final String table;
  final String client;
  final String status;
  final String colArticle;
  final String colQty;
  final String colTotal;
  final String subtotal;
  final String total;

  factory ReceiptPdfLabels.french() => ReceiptPdfLabels._(
        date: 'Date',
        service: 'Service',
        table: 'Table',
        client: 'Client',
        status: 'Statut',
        colArticle: 'Article',
        colQty: 'Qte',
        colTotal: 'Total',
        subtotal: 'Sous-total',
        total: 'Total',
      );

  factory ReceiptPdfLabels.arabic() => ReceiptPdfLabels.french();

  String receiptNo(int n) => 'Ticket #$n';

  String serviceType(String t) => t == 'DINE_IN' ? 'Sur place' : t;

  String orderStatus(String s) => s;
}

class ReceiptPdfResult {
  const ReceiptPdfResult(this.bytes);
  final Uint8List bytes;
}

Future<ReceiptPdfResult> exportOrderReceiptPdf({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  final L = arabic ? ReceiptPdfLabels.arabic() : ReceiptPdfLabels.french();
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(restaurantName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(L.receiptNo(order.orderNumber)),
          pw.SizedBox(height: 8),
          for (final line in order.items)
            pw.Text('${line.displayNameLocalized(arabic)} x${line.quantity}'),
          pw.Divider(),
          pw.Text('${L.total}: ${order.totals.subtotal} FCFA'),
        ],
      ),
    ),
  );
  return ReceiptPdfResult(Uint8List.fromList(await doc.save()));
}
