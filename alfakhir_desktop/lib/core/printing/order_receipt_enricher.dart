import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';

const String _snapshotNameSeparator = '\u001F';

/// Parse "Nom FR|Nom AR" stocké dans productNameSnapshot côté API.
({String name, String? nameAr}) parseProductSnapshot(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return (name: '', nameAr: null);
  final sep = s.indexOf(_snapshotNameSeparator);
  if (sep < 0) return (name: s, nameAr: null);
  final fr = s.substring(0, sep).trim();
  final ar = s.substring(sep + 1).trim();
  return (name: fr, nameAr: ar.isEmpty ? null : ar);
}

/// Construit la valeur productNameSnapshot pour l'API (FR + AR).
String buildProductNameSnapshot(String nameFr, String? nameAr) {
  final fr = nameFr.trim();
  final ar = nameAr?.trim() ?? '';
  if (ar.isEmpty) return fr;
  return '$fr$_snapshotNameSeparator$ar';
}

ProductDto? _matchCatalogProduct(
  OrderLineDto line,
  Map<String, ProductDto> byId,
  Map<String, ProductDto> byName,
) {
  if (line.productId.isNotEmpty) {
    final p = byId[line.productId];
    if (p != null) return p;
  }
  final key = line.productName.trim().toLowerCase();
  if (key.isNotEmpty) return byName[key];
  return null;
}

/// Complète les noms FR + AR des lignes pour la facture/ticket.
OrderDetailDto enrichOrderForReceipt(
  OrderDetailDto order, {
  List<ProductDto>? catalog,
}) {
  if (catalog == null || catalog.isEmpty) return order;

  final byId = {for (final p in catalog) p.id: p};
  final byName = <String, ProductDto>{};
  for (final p in catalog) {
    final key = p.name.trim().toLowerCase();
    if (key.isNotEmpty) byName[key] = p;
  }

  var changed = false;
  final items = order.items.map((line) {
    var name = line.productName.trim();
    var nameAr = line.productNameAr?.trim();

    final p = _matchCatalogProduct(line, byId, byName);
    if (p != null) {
      if (name.isEmpty) name = p.name.trim();
      if (nameAr == null || nameAr.isEmpty) {
        final ar = p.nameAr?.trim();
        if (ar != null && ar.isNotEmpty) nameAr = ar;
      }
      if (line.productId.isEmpty) {
        changed = true;
      }
    }

    if (name.isEmpty) name = 'Article';
    final arOut = (nameAr != null && nameAr.isNotEmpty) ? nameAr : null;

    if (name == line.productName.trim() &&
        arOut == line.productNameAr?.trim() &&
        (line.productId.isNotEmpty || p == null)) {
      return line;
    }

    changed = true;
    return OrderLineDto(
      productId: line.productId.isNotEmpty ? line.productId : (p?.id ?? ''),
      productName: name,
      productNameAr: arOut,
      quantity: line.quantity,
      unitPrice: line.unitPrice,
      lineTotal: line.lineTotal,
    );
  }).toList();

  if (!changed) return order;
  return OrderDetailDto(
    id: order.id,
    orderNumber: order.orderNumber,
    serviceType: order.serviceType,
    status: order.status,
    createdAt: order.createdAt,
    diningTable: order.diningTable,
    customer: order.customer,
    items: items,
    totals: order.totals,
  );
}
