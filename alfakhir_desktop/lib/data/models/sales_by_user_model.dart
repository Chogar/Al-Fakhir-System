import 'dashboard_sales_breakdown_model.dart';

class SalesByUserRowDto {
  const SalesByUserRowDto({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.displayName,
    required this.orderCount,
    required this.revenueFcfa,
    required this.share,
  });

  final String? userId;
  final String? username;
  final String? fullName;
  final String displayName;
  final int orderCount;
  final String revenueFcfa;
  final double share;

  factory SalesByUserRowDto.fromJson(Map<String, dynamic> j) {
    return SalesByUserRowDto(
      userId: j['userId'] as String?,
      username: j['username'] as String?,
      fullName: j['fullName'] as String?,
      displayName: j['displayName'] as String? ?? '—',
      orderCount: (j['orderCount'] as num?)?.toInt() ?? 0,
      revenueFcfa: j['revenueFcfa']?.toString() ?? '0',
      share: (j['share'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesByUserReportDto {
  const SalesByUserReportDto({
    required this.period,
    required this.periodFrom,
    required this.periodTo,
    required this.totalRevenueFcfa,
    required this.totalOrders,
    required this.users,
    required this.products,
  });

  final String period;
  final String periodFrom;
  final String periodTo;
  final String totalRevenueFcfa;
  final int totalOrders;
  final List<SalesByUserRowDto> users;
  final List<TopProductRowDto> products;

  factory SalesByUserReportDto.fromJson(Map<String, dynamic> j) {
    final rawUsers = j['users'] as List<dynamic>? ?? [];
    final rawProducts = j['products'] as List<dynamic>? ?? [];
    return SalesByUserReportDto(
      period: j['period'] as String? ?? 'month',
      periodFrom: j['periodFrom'] as String? ?? '',
      periodTo: j['periodTo'] as String? ?? '',
      totalRevenueFcfa: j['totalRevenueFcfa']?.toString() ?? '0',
      totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
      users: rawUsers
          .map((e) => SalesByUserRowDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      products: rawProducts
          .map((e) => TopProductRowDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
