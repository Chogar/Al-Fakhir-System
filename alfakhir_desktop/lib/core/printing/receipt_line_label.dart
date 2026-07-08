import '../../data/models/order_model.dart';

/// Libellé quantité + montant pour une ligne de ticket.
String receiptLinePriceSuffix(OrderLineDto line) {
  final unit = double.tryParse(line.unitPrice.replaceAll(',', '.')) ?? 0;
  final total = unit * line.quantity;
  final amount = total == total.roundToDouble()
      ? total.toStringAsFixed(0)
      : total.toStringAsFixed(2);
  return '  x${line.quantity}  $amount FCFA';
}

/// Écrit une ligne article : nom FR, nom AR (si présent), puis prix.
void writeReceiptLineItem(StringBuffer buffer, OrderLineDto line) {
  final fr = line.productName.trim();
  final ar = line.productNameAr?.trim() ?? '';
  final price = receiptLinePriceSuffix(line);

  if (fr.isNotEmpty && ar.isNotEmpty && ar != fr) {
    buffer.writeln('$fr$price');
    buffer.writeln(ar);
  } else if (fr.isNotEmpty) {
    buffer.writeln('$fr$price');
  } else if (ar.isNotEmpty) {
    buffer.writeln('$ar$price');
  } else {
    buffer.writeln('Article$price');
  }
}

bool receiptLineHasArabicName(OrderLineDto line) {
  final ar = line.productNameAr?.trim() ?? '';
  final fr = line.productName.trim();
  return ar.isNotEmpty && ar != fr;
}
