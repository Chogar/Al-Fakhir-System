import '../../data/models/order_model.dart';
import 'receipt_pdf.dart';

String buildReceiptTicketText({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
}) {
  final l = arabic ? ReceiptPdfLabels.arabic() : ReceiptPdfLabels.french();
  final b = StringBuffer()
    ..writeln(restaurantName)
    ..writeln(l.receiptNo(order.orderNumber))
    ..writeln('-' * 32)
    ..writeln('${l.date}: ${_fmtDate(order.createdAt)}')
    ..writeln('${l.service}: ${l.serviceType(order.serviceType)}');

  if (order.diningTable != null) {
    b.writeln('${l.table}: ${order.diningTable!.number}');
  }
  if (order.customer != null) {
    b.writeln('${l.client}: ${order.customer!.name}');
  }

  b..writeln('-' * 32);
  for (final line in order.items) {
    final total = (double.tryParse(line.unitPrice.replaceAll(',', '.')) ?? 0) *
        line.quantity;
    b.writeln(
      '${line.displayNameLocalized(arabic)}  x${line.quantity}  ${_fmtAmount(total.toString())} FCFA',
    );
  }
  b
    ..writeln('-' * 32)
    ..writeln('${l.total}: ${_fmtAmount(order.totals.subtotal)} FCFA')
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
