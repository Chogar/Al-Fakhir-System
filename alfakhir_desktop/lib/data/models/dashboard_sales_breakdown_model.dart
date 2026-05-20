class DashboardSalesBreakdownDto {
  const DashboardSalesBreakdownDto({
    required this.period,
    required this.periodFrom,
    required this.periodTo,
    required this.totalRevenueFcfa,
    required this.totalOrders,
    required this.topProducts,
    required this.byCategory,
  });

  final String period;
  final String periodFrom;
  final String periodTo;
  final String totalRevenueFcfa;
  final int totalOrders;
  final List<TopProductRowDto> topProducts;
  final List<CategorySalesRowDto> byCategory;

  factory DashboardSalesBreakdownDto.fromJson(Map<String, dynamic> j) {
    final tops = j['topProducts'];
    final cats = j['byCategory'];
    return DashboardSalesBreakdownDto(
      period: j['period']?.toString() ?? 'month',
      periodFrom: j['periodFrom']?.toString() ?? '',
      periodTo: j['periodTo']?.toString() ?? '',
      totalRevenueFcfa: j['totalRevenueFcfa']?.toString() ?? '0',
      totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
      topProducts: tops is List
          ? tops
              .whereType<Map>()
              .map((e) => TopProductRowDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      byCategory: cats is List
          ? cats
              .whereType<Map>()
              .map((e) => CategorySalesRowDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class TopProductRowDto {
  const TopProductRowDto({
    required this.name,
    required this.quantity,
    required this.revenueFcfa,
  });

  final String name;
  final int quantity;
  final String revenueFcfa;

  factory TopProductRowDto.fromJson(Map<String, dynamic> j) {
    return TopProductRowDto(
      name: j['name']?.toString() ?? '—',
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      revenueFcfa: j['revenueFcfa']?.toString() ?? '0',
    );
  }
}

class CategorySalesRowDto {
  const CategorySalesRowDto({
    required this.categoryName,
    required this.quantity,
    required this.revenueFcfa,
    required this.share,
  });

  final String categoryName;
  final int quantity;
  final String revenueFcfa;
  final double share;

  factory CategorySalesRowDto.fromJson(Map<String, dynamic> j) {
    return CategorySalesRowDto(
      categoryName: j['categoryName']?.toString() ?? '—',
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      revenueFcfa: j['revenueFcfa']?.toString() ?? '0',
      share: (j['share'] as num?)?.toDouble() ?? 0,
    );
  }
}
