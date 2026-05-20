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
    return OrderLineDto(
      productId: j['productId']?.toString() ?? '',
      productName: j['productName']?.toString() ?? '',
      productNameAr: j['productNameAr'] as String?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: j['unitPrice']?.toString() ?? '0',
      lineTotal: j['lineTotal']?.toString() ?? '0',
    );
  }

  String displayNameLocalized(bool arabic) {
    if (arabic && (productNameAr?.trim().isNotEmpty ?? false)) {
      return productNameAr!.trim();
    }
    return productName;
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
      items: (j['items'] as List? ?? [])
          .map((e) => OrderLineDto.fromJson(e as Map<String, dynamic>))
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
