enum FinancePeriod { day, week, month, year, custom }

String financePeriodApiValue(FinancePeriod p) => switch (p) {
      FinancePeriod.day => 'day',
      FinancePeriod.week => 'week',
      FinancePeriod.month => 'month',
      FinancePeriod.year => 'year',
      FinancePeriod.custom => 'custom',
    };

String financePeriodCaptionFr(FinancePeriod p) => switch (p) {
      FinancePeriod.day => 'Jour',
      FinancePeriod.week => 'Semaine',
      FinancePeriod.month => 'Mois',
      FinancePeriod.year => 'Année',
      FinancePeriod.custom => 'Personnalisé',
    };

String financePeriodSubtitleFr(FinancePeriod p) => switch (p) {
      FinancePeriod.day => 'du jour',
      FinancePeriod.week => 'de la semaine',
      FinancePeriod.month => 'du mois',
      FinancePeriod.year => 'de l’année',
      FinancePeriod.custom => 'sur la période',
    };

String _two(int n) => n.toString().padLeft(2, '0');

String toIsoDateOnly(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)}';

FinancePeriod financePeriodFromApi(String? raw) => switch (raw) {
      'day' => FinancePeriod.day,
      'week' => FinancePeriod.week,
      'year' => FinancePeriod.year,
      _ => FinancePeriod.month,
    };

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lundi comme premier jour de la semaine (comme le backend).
DateTime startOfCalendarWeekMonday(DateTime d) {
  final x = _dateOnly(d);
  return x.subtract(Duration(days: x.weekday - 1));
}

DateTime endOfCalendarWeekSunday(DateTime d) =>
    startOfCalendarWeekMonday(d).add(const Duration(days: 6));

(DateTime start, DateTime end) boundsForFinancePeriod(FinancePeriod p,
    [DateTime? reference]) {
  final now = reference ?? DateTime.now();
  final day = _dateOnly(now);
  switch (p) {
    case FinancePeriod.day:
      return (day, day);
    case FinancePeriod.week:
      return (startOfCalendarWeekMonday(now), endOfCalendarWeekSunday(now));
    case FinancePeriod.month:
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1, 0);
      return (start, end);
    case FinancePeriod.year:
      return (DateTime(now.year), DateTime(now.year, 12, 31));
    case FinancePeriod.custom:
      // Pour la période personnalisée, les bornes proviennent de l'extérieur ;
      // par défaut on renvoie le mois courant pour rester cohérent.
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1, 0);
      return (start, end);
  }
}

(String fromIso, String toIso) isoRangeForExpenseFilter(FinancePeriod p,
    [DateTime? reference]) {
  final (start, end) = boundsForFinancePeriod(p, reference);
  return (toIsoDateOnly(start), toIsoDateOnly(end));
}
