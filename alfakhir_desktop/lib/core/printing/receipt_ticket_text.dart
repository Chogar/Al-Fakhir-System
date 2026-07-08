import '../../data/models/order_model.dart';
import 'receipt_discount.dart';
import 'receipt_line_label.dart';
import 'receipt_pdf.dart';

String buildReceiptTicketText({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) {
  final l = arabic ? ReceiptPdfLabels.arabic() : ReceiptPdfLabels.french();
  final b = StringBuffer()
    ..writeln(restaurantName)
    ..writeln(l.receiptNo(order.orderNumber))
    ..writeln('-' * 32)
    ..writeln('${l.date}: ${_fmtDate(order.createdAt)}')
    ..writeln('${l.service}: ${l.serviceType(order.serviceType)}');

  if (order.customer != null) {
    b.writeln('${l.client}: ${order.customer!.name}');
  }

  b.writeln('-' * 32);
  for (final line in order.items) {
    writeReceiptLineItem(b, line);
  }
  b.writeln('-' * 32);

  final discount = resolveReceiptDiscountFcfa(
    order,
    discountFcfa: discountFcfa,
  );
  final netTotal = resolveReceiptNetTotalFcfa(
    order,
    discountFcfa: discountFcfa,
  );

  b.writeln('${l.subtotal}: ${_fmtAmount(order.totals.subtotal)} FCFA');
  if (discount > 0.009) {
    b.writeln('${l.discount}: -${_fmtAmount(discount.toString())} FCFA');
  }
  b
    ..writeln('${l.total}: ${_fmtAmount(netTotal.toString())} FCFA')
    ..writeln();
  return b.toString();
}

String _fmtDate(String iso) {
  if (iso.length < 16) return iso;
  return iso.substring(0, 16).replaceFirst('T', ' ');
}

String _fmtAmount(String raw) {
  final n = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}
