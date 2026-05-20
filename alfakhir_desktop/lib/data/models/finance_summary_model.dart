class FinanceSummaryDto {
  const FinanceSummaryDto({
    required this.revenueTodayFcfa,
    required this.expensesTodayFcfa,
    required this.revenuePeriodFcfa,
    required this.expensesPeriodFcfa,
    required this.period,
    required this.periodFrom,
    required this.periodTo,
  });

  final String revenueTodayFcfa;
  final String expensesTodayFcfa;
  final String revenuePeriodFcfa;
  final String expensesPeriodFcfa;
  final String period;
  final String periodFrom;
  final String periodTo;

  factory FinanceSummaryDto.fromJson(Map<String, dynamic> j) {
    return FinanceSummaryDto(
      revenueTodayFcfa: j['revenueTodayFcfa']?.toString() ?? '0',
      expensesTodayFcfa: j['expensesTodayFcfa']?.toString() ?? '0',
      revenuePeriodFcfa: j['revenuePeriodFcfa']?.toString() ?? '0',
      expensesPeriodFcfa: j['expensesPeriodFcfa']?.toString() ?? '0',
      period: j['period']?.toString() ?? 'month',
      periodFrom: j['periodFrom']?.toString() ?? '',
      periodTo: j['periodTo']?.toString() ?? '',
    );
  }
}
