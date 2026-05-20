class DashboardOverviewDto {
  const DashboardOverviewDto({
    required this.tablesTotal,
    required this.tablesFree,
    required this.tablesOccupied,
    required this.tablesReserved,
    required this.tablesCleaning,
    required this.reservationsToday,
    required this.ordersInProgress,
  });

  final int tablesTotal;
  final int tablesFree;
  final int tablesOccupied;
  final int tablesReserved;
  final int tablesCleaning;
  final int reservationsToday;
  final int ordersInProgress;

  factory DashboardOverviewDto.fromJson(Map<String, dynamic> j) {
    final t = j['tables'];
    final tables = t is Map<String, dynamic> ? t : const <String, dynamic>{};
    return DashboardOverviewDto(
      tablesTotal: (tables['total'] as num?)?.toInt() ?? 0,
      tablesFree: (tables['free'] as num?)?.toInt() ?? 0,
      tablesOccupied: (tables['occupied'] as num?)?.toInt() ?? 0,
      tablesReserved: (tables['reserved'] as num?)?.toInt() ?? 0,
      tablesCleaning: (tables['cleaning'] as num?)?.toInt() ?? 0,
      reservationsToday: (j['reservationsToday'] as num?)?.toInt() ?? 0,
      ordersInProgress: (j['ordersInProgress'] as num?)?.toInt() ?? 0,
    );
  }
}
