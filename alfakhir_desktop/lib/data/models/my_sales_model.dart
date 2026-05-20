import 'sales_breakdown_model.dart';

/// Ventes personnelles du caissier / serveur ([GET /dashboard/my-sales]).
class MySalesDto {
  const MySalesDto({
    required this.period,
    required this.periodFrom,
    required this.periodTo,
    required this.revenueTodayFcfa,
    required this.orderCountToday,
    required this.revenuePeriodFcfa,
    required this.orderCountPeriod,
    required this.breakdown,
  });

  final String period;
  final String periodFrom;
  final String periodTo;
  final String revenueTodayFcfa;
  final int orderCountToday;
  final String revenuePeriodFcfa;
  final int orderCountPeriod;
  final SalesBreakdownDto breakdown;

  factory MySalesDto.fromJson(Map<String, dynamic> j) {
    return MySalesDto(
      period: j['period']?.toString() ?? 'month',
      periodFrom: j['periodFrom']?.toString() ?? '',
      periodTo: j['periodTo']?.toString() ?? '',
      revenueTodayFcfa: j['revenueTodayFcfa']?.toString() ?? '0',
      orderCountToday: (j['orderCountToday'] as num?)?.toInt() ?? 0,
      revenuePeriodFcfa: j['revenuePeriodFcfa']?.toString() ?? '0',
      orderCountPeriod: (j['orderCountPeriod'] as num?)?.toInt() ?? 0,
      breakdown: SalesBreakdownDto.fromJson(j),
    );
  }
}
