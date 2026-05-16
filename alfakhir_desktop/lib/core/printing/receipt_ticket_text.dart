import '../../data/models/order_model.dart';
import 'receipt_pdf.dart';

/// Contenu texte du ticket (partagé impression texte / RAW).
String buildReceiptTicketText({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
}) {
  final L = arabic ? ReceiptPdfLabels.arabic() : ReceiptPdfLabels.french();
  final subtotal =
      double.tryParse(order.totals.subtotal.replaceAll(',', '.')) ?? 0;
  final discount = discountFcfa.clamp(0, subtotal);
  final total = subtotal - discount;

  final buf = StringBuffer()
    ..writeln(restaurantName)
    ..writeln(L.receiptNo(order.orderNumber))
    ..writeln('-' * 32)
    ..writeln('${L.date} : ${_fmtDate(order.createdAt)}')
    ..writeln('${L.service} : ${L.serviceType(order.serviceType)}');
  if (order.diningTable != null) {
    buf.writeln('${L.table} : ${order.diningTable!.number}');
  }
  if (order.customer != null) {
    buf.writeln('${L.client} : ${order.customer!.name}');
  }
  buf.writeln('-' * 32);
  for (final line in order.items) {
    final name = line.displayNameLocalized(arabic);
    final total = _fmtAmount(
      ((double.tryParse(line.unitPrice.replaceAll(',', '.')) ?? 0) *
              line.quantity)
          .toString(),
    );
    buf.writeln('$name  x${line.quantity}  $total FCFA');
  }
  buf
    ..writeln('-' * 32)
    ..writeln('${L.subtotal} : ${_fmtAmount(order.totals.subtotal)} FCFA');
  if (discount > 0.009) {
    buf.writeln('${L.discount} : -${_fmtAmount(discount.toString())} FCFA');
  }
  buf.writeln('${L.total} : ${_fmtAmount(total.toString())} FCFA');
  if ((order.notes ?? '').isNotEmpty) {
    buf.writeln(L.noteLine(order.notes!));
  }
  buf
    ..writeln()
    ..writeln(L.customerFooter)
    ..writeln();
  return buf.toString();
}

String _fmtDate(String iso) {
  if (iso.length < 16) return iso;
  return iso.substring(0, 16).replaceFirst('T', ' ');
}

String _fmtAmount(String raw) {
  final n = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  if (n == n.roundToDouble()) return n.toStringAsFixed(0);
  return n.toStringAsFixed(2);
}
