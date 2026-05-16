class DashboardFinanceSummaryDto {
  const DashboardFinanceSummaryDto({
    required this.revenueTodayFcfa,
    required this.expensesTodayFcfa,
    required this.revenuePeriodFcfa,
    required this.expensesPeriodFcfa,
    required this.period,
    this.periodFrom,
    this.periodTo,
  });

  final String revenueTodayFcfa;
  final String expensesTodayFcfa;
  final String revenuePeriodFcfa;
  final String expensesPeriodFcfa;

  /// `day` | `week` | `month` | `year` | `custom`
  final String period;

  /// Bornes ISO `YYYY-MM-DD` effectivement appliquées (utile pour l'affichage).
  final String? periodFrom;
  final String? periodTo;

  factory DashboardFinanceSummaryDto.fromJson(Map<String, dynamic> j) {
    final legacyRev = j['revenueMonthFcfa']?.toString();
    final legacyExp = j['expensesMonthFcfa']?.toString();
    return DashboardFinanceSummaryDto(
      revenueTodayFcfa: j['revenueTodayFcfa']?.toString() ?? '0',
      expensesTodayFcfa: j['expensesTodayFcfa']?.toString() ?? '0',
      revenuePeriodFcfa:
          j['revenuePeriodFcfa']?.toString() ?? legacyRev ?? '0',
      expensesPeriodFcfa:
          j['expensesPeriodFcfa']?.toString() ?? legacyExp ?? '0',
      period: j['period']?.toString() ?? 'month',
      periodFrom: j['periodFrom']?.toString(),
      periodTo: j['periodTo']?.toString(),
    );
  }
}
