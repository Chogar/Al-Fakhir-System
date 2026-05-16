class OrderTableRefDto {
  const OrderTableRefDto({required this.id, required this.number});

  final String id;
  final int number;

  factory OrderTableRefDto.fromJson(Map<String, dynamic> j) {
    return OrderTableRefDto(
      id: j['id'] as String,
      number: (j['number'] as num).toInt(),
    );
  }
}

class OrderCustomerRefDto {
  const OrderCustomerRefDto({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;

  factory OrderCustomerRefDto.fromJson(Map<String, dynamic> j) {
    return OrderCustomerRefDto(
      id: j['id'] as String,
      name: j['name'] as String,
      phone: (j['phone'] as String?) ?? '',
    );
  }
}

class OrderLineProductDto {
  const OrderLineProductDto({
    required this.id,
    required this.name,
    this.nameAr,
    required this.price,
  });

  final String id;
  final String name;
  final String? nameAr;
  final String price;

  factory OrderLineProductDto.fromJson(Map<String, dynamic> j) {
    final raw = j['price'];
    final priceStr =
        raw is num ? raw.toString() : (raw as String? ?? '0');
    return OrderLineProductDto(
      id: j['id'] as String,
      name: j['name'] as String,
      nameAr: j['nameAr'] as String?,
      price: priceStr,
    );
  }
}

class OrderLineDto {
  const OrderLineDto({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.productNameSnapshot,
    required this.product,
  });

  final String id;
  final int quantity;
  final String unitPrice;
  final String? productNameSnapshot;
  final OrderLineProductDto? product;

  factory OrderLineDto.fromJson(Map<String, dynamic> j) {
    final rawPrice = j['unitPrice'];
    final unitPrice =
        rawPrice is num ? rawPrice.toString() : (rawPrice as String? ?? '0');
    final prod = j['product'];
    return OrderLineDto(
      id: j['id'] as String,
      quantity: (j['quantity'] as num).toInt(),
      unitPrice: unitPrice,
      productNameSnapshot: j['productNameSnapshot'] as String?,
      product: prod is Map<String, dynamic>
          ? OrderLineProductDto.fromJson(prod)
          : null,
    );
  }

  String displayNameLocalized(bool preferArabic) {
    final p = product;
    if (p != null) {
      if (preferArabic) {
        final ar = p.nameAr;
        if (ar != null && ar.trim().isNotEmpty) {
          return ar.trim();
        }
      }
      return p.name;
    }
    final snap = productNameSnapshot;
    if (snap != null && snap.isNotEmpty) return snap;
    return 'Article';
  }

  /// Libellé FR (comportement historique).
  String get displayName => displayNameLocalized(false);
}

class OrderPaymentDto {
  const OrderPaymentDto({
    required this.id,
    required this.amount,
    required this.method,
    required this.reference,
    required this.createdAt,
  });

  final String id;
  final String amount;
  final String method;
  final String? reference;
  final String createdAt;

  factory OrderPaymentDto.fromJson(Map<String, dynamic> j) {
    final raw = j['amount'];
    final amt =
        raw is num ? raw.toString() : (raw as String? ?? '0');
    return OrderPaymentDto(
      id: j['id'] as String,
      amount: amt,
      method: j['method'] as String,
      reference: j['reference'] as String?,
      createdAt: j['createdAt']?.toString() ?? '',
    );
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
    String s(dynamic v) => v == null ? '0' : v.toString();
    return OrderTotalsDto(
      subtotal: s(j['subtotal']),
      paid: s(j['paid']),
      due: s(j['due']),
    );
  }
}

class OrderDetailDto {
  const OrderDetailDto({
    required this.id,
    required this.orderNumber,
    required this.serviceType,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.diningTable,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totals,
  });

  final String id;
  final int orderNumber;
  final String serviceType;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final OrderTableRefDto? diningTable;
  final OrderCustomerRefDto? customer;
  final List<OrderLineDto> items;
  final List<OrderPaymentDto> payments;
  final OrderTotalsDto totals;

  factory OrderDetailDto.fromJson(Map<String, dynamic> j) {
    final dt = j['diningTable'];
    final cust = j['customer'];
    final itemsRaw = j['items'] as List<dynamic>? ?? [];
    final paysRaw = j['payments'] as List<dynamic>? ?? [];
    final totalsRaw = j['totals'];
    if (totalsRaw is! Map<String, dynamic>) {
      throw const FormatException('totaux commande invalides');
    }
    return OrderDetailDto(
      id: j['id'] as String,
      orderNumber: (j['orderNumber'] as num).toInt(),
      serviceType: j['serviceType'] as String,
      status: j['status'] as String,
      notes: j['notes'] as String?,
      createdAt: j['createdAt']?.toString() ?? '',
      updatedAt: j['updatedAt']?.toString() ?? '',
      diningTable: dt is Map<String, dynamic>
          ? OrderTableRefDto.fromJson(dt)
          : null,
      customer: cust is Map<String, dynamic>
          ? OrderCustomerRefDto.fromJson(cust)
          : null,
      items: itemsRaw
          .map((e) => OrderLineDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: paysRaw
          .map((e) => OrderPaymentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: OrderTotalsDto.fromJson(totalsRaw),
    );
  }
}
