class OrderTableRefDto {
  const OrderTableRefDto({required this.id, required this.number});
  final String id;
  final String number;
  factory OrderTableRefDto.fromJson(Map<String, dynamic> j) =>
      OrderTableRefDto(id: j['id']?.toString() ?? '', number: j['number']?.toString() ?? '');
}

class OrderCustomerRefDto {
  const OrderCustomerRefDto({required this.id, required this.name});
  final String id;
  final String name;
  factory OrderCustomerRefDto.fromJson(Map<String, dynamic> j) =>
      OrderCustomerRefDto(id: j['id']?.toString() ?? '', name: j['name']?.toString() ?? '');
}

Map<String, dynamic>? _jsonMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

bool _usableReceiptLabel(String? value) {
  if (value == null) return false;
  final t = value.trim();
  if (t.isEmpty) return false;
  if (RegExp(r'^[?\s\uFFFD]+$').hasMatch(t)) return false;
  return true;
}

class OrderLineDto {
  const OrderLineDto({
    required this.productId,
    required this.productName,
    this.productNameAr,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productId;
  final String productName;
  final String? productNameAr;
  final int quantity;
  final String unitPrice;
  final String lineTotal;

  factory OrderLineDto.fromJson(Map<String, dynamic> j) {
    final productMap = _jsonMap(j['product']);

    var name = j['productName']?.toString().trim() ?? '';
    if (name.isEmpty) {
      name = j['productNameSnapshot']?.toString().trim() ?? '';
    }
    if (name.isEmpty && productMap != null) {
      name = productMap['name']?.toString().trim() ?? '';
    }

    var nameAr = j['productNameAr'] as String?;
    if ((nameAr == null || nameAr.trim().isEmpty) && productMap != null) {
      nameAr = productMap['nameAr'] as String?;
    }

    final qty = (j['quantity'] as num?)?.toInt() ?? 0;
    final unit = j['unitPrice']?.toString() ?? '0';
    var lineTotal = j['lineTotal']?.toString() ?? '';
    if (lineTotal.isEmpty && qty > 0) {
      final u = double.tryParse(unit.replaceAll(',', '.')) ?? 0;
      lineTotal = (u * qty).toStringAsFixed(2);
    }

    final productId = j['productId']?.toString() ??
        productMap?['id']?.toString() ??
        '';

    return OrderLineDto(
      productId: productId,
      productName: name,
      productNameAr: nameAr,
      quantity: qty,
      unitPrice: unit,
      lineTotal: lineTotal.isEmpty ? '0' : lineTotal,
    );
  }

  String displayNameLocalized(bool arabic) {
    if (arabic && (productNameAr?.trim().isNotEmpty ?? false)) {
      return productNameAr!.trim();
    }
    final fr = productName.trim();
    if (fr.isNotEmpty) return fr;
    return productNameAr?.trim() ?? '';
  }

  /// Libellé garanti non vide pour ticket / facture (évite noms arabes corrompus).
  String labelForReceipt(bool arabic) {
    if (arabic && _usableReceiptLabel(productNameAr)) {
      return productNameAr!.trim();
    }
    if (_usableReceiptLabel(productName)) return productName.trim();
    if (_usableReceiptLabel(productNameAr)) return productNameAr!.trim();
    return 'Article';
  }
}

class OrderTotalsDto {
  const OrderTotalsDto({
    required this.subtotal,
    required this.paid,
    required this.due,
  });

  final String subtotal;
  final String paid;
  final String due;

  factory OrderTotalsDto.fromJson(Map<String, dynamic> j) {
    return OrderTotalsDto(
      subtotal: j['subtotal']?.toString() ?? '0',
      paid: j['paid']?.toString() ?? '0',
      due: j['due']?.toString() ?? '0',
    );
  }
}

class OrderDetailDto {
  const OrderDetailDto({
    required this.id,
    required this.orderNumber,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.diningTable,
    this.customer,
    this.notes,
    required this.items,
    required this.totals,
  });

  final String id;
  final int orderNumber;
  final String serviceType;
  final String status;
  final String createdAt;
  final OrderTableRefDto? diningTable;
  final OrderCustomerRefDto? customer;
  final String? notes;
  final List<OrderLineDto> items;
  final OrderTotalsDto totals;

  factory OrderDetailDto.fromJson(Map<String, dynamic> j) {
    return OrderDetailDto(
      id: j['id']?.toString() ?? '',
      orderNumber: (j['orderNumber'] as num?)?.toInt() ?? 0,
      serviceType: j['serviceType']?.toString() ?? 'DINE_IN',
      status: j['status']?.toString() ?? '',
      createdAt: j['createdAt']?.toString() ?? '',
      diningTable: j['diningTable'] is Map
          ? OrderTableRefDto.fromJson(j['diningTable'] as Map<String, dynamic>)
          : null,
      customer: j['customer'] is Map
          ? OrderCustomerRefDto.fromJson(j['customer'] as Map<String, dynamic>)
          : null,
      notes: j['notes'] as String?,
      items: (j['items'] as List? ?? [])
          .map((e) => OrderLineDto.fromJson(_jsonMap(e) ?? const {}))
          .toList(),
      totals: OrderTotalsDto.fromJson(
        (j['totals'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class OrderSummaryDto {
  const OrderSummaryDto({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.totalFcfa,
  });

  final String id;
  final int orderNumber;
  final String status;
  final String createdAt;
  final String totalFcfa;

  factory OrderSummaryDto.fromJson(Map<String, dynamic> j) {
    return OrderSummaryDto(
      id: j['id']?.toString() ?? '',
      orderNumber: (j['orderNumber'] as num?)?.toInt() ?? 0,
      status: j['status']?.toString() ?? '',
      createdAt: j['createdAt']?.toString() ?? '',
      totalFcfa: j['totalFcfa']?.toString() ?? j['subtotal']?.toString() ?? '0',
    );
  }
}
