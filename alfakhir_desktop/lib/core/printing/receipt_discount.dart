import '../../data/models/order_model.dart';

/// Montant remise pour le ticket (saisie caisse ou paiement API `REMISE`).
double resolveReceiptDiscountFcfa(
  OrderDetailDto order, {
  double discountFcfa = 0,
}) {
  final subtotal =
      double.tryParse(order.totals.subtotal.replaceAll(',', '.')) ?? 0;
  var fromPayments = 0.0;
  for (final p in order.payments) {
    if (p.isRemise) {
      fromPayments +=
          double.tryParse(p.amount.replaceAll(',', '.')) ?? 0;
    }
  }
  final fromUi = discountFcfa.clamp(0, subtotal).toDouble();
  if (fromPayments > fromUi) return fromPayments;
  return fromUi;
}

/// Montant encaissé (hors ligne remise comptable).
double resolveReceiptNetTotalFcfa(
  OrderDetailDto order, {
  double discountFcfa = 0,
}) {
  final subtotal =
      double.tryParse(order.totals.subtotal.replaceAll(',', '.')) ?? 0;
  final discount = resolveReceiptDiscountFcfa(
    order,
    discountFcfa: discountFcfa,
  );
  return (subtotal - discount).clamp(0.0, double.infinity);
}
