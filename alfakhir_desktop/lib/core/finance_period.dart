enum FinancePeriod { today, week, month, year, custom }

String financePeriodApiValue(FinancePeriod p) {
  switch (p) {
    case FinancePeriod.today:
      return 'today';
    case FinancePeriod.week:
      return 'week';
    case FinancePeriod.month:
      return 'month';
    case FinancePeriod.year:
      return 'year';
    case FinancePeriod.custom:
      return 'custom';
  }
}

String toIsoDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
