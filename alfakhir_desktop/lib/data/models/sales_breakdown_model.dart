/// Statistiques de vente sur une période (top produits + répartition catégorie).
class SalesBreakdownDto {
  const SalesBreakdownDto({
    required this.period,
    required this.periodFrom,
    required this.periodTo,
    required this.totalRevenueFcfa,
    required this.totalOrders,
    required this.totalUnits,
    required this.topProducts,
    required this.byCategory,
  });

  final String period;
  final String periodFrom;
  final String periodTo;
  final String totalRevenueFcfa;
  final int totalOrders;
  final int totalUnits;
  final List<TopProductDto> topProducts;
  final List<CategoryBreakdownDto> byCategory;

  factory SalesBreakdownDto.fromJson(Map<String, dynamic> j) {
    return SalesBreakdownDto(
      period: j['period']?.toString() ?? 'month',
      periodFrom: j['periodFrom']?.toString() ?? '',
      periodTo: j['periodTo']?.toString() ?? '',
      totalRevenueFcfa: j['totalRevenueFcfa']?.toString() ?? '0',
      totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
      totalUnits: (j['totalUnits'] as num?)?.toInt() ?? 0,
      topProducts: ((j['topProducts'] as List?) ?? const [])
          .map((e) => TopProductDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      byCategory: ((j['byCategory'] as List?) ?? const [])
          .map((e) =>
              CategoryBreakdownDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TopProductDto {
  const TopProductDto({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenueFcfa,
  });

  final String? productId;
  final String name;
  final int quantity;
  final String revenueFcfa;

  factory TopProductDto.fromJson(Map<String, dynamic> j) {
    return TopProductDto(
      productId: j['productId']?.toString(),
      name: j['name']?.toString() ?? '',
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      revenueFcfa: j['revenueFcfa']?.toString() ?? '0',
    );
  }
}

class CategoryBreakdownDto {
  const CategoryBreakdownDto({
    required this.categoryId,
    required this.categoryName,
    required this.quantity,
    required this.revenueFcfa,
    required this.share,
  });

  final String? categoryId;
  final String categoryName;
  final int quantity;
  final String revenueFcfa;
  final double share;

  factory CategoryBreakdownDto.fromJson(Map<String, dynamic> j) {
    return CategoryBreakdownDto(
      categoryId: j['categoryId']?.toString(),
      categoryName: j['categoryName']?.toString() ?? '',
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      revenueFcfa: j['revenueFcfa']?.toString() ?? '0',
      share: (j['share'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
