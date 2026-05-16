// Réponse [GET /dashboard/overview].

class TablesOverview {
  const TablesOverview({
    required this.total,
    required this.free,
    required this.occupied,
    required this.reserved,
    required this.cleaning,
  });

  final int total;
  final int free;
  final int occupied;
  final int reserved;
  final int cleaning;

  factory TablesOverview.fromJson(Map<String, dynamic> j) {
    return TablesOverview(
      total: (j['total'] as num).toInt(),
      free: (j['free'] as num).toInt(),
      occupied: (j['occupied'] as num).toInt(),
      reserved: (j['reserved'] as num).toInt(),
      cleaning: (j['cleaning'] as num).toInt(),
    );
  }
}

class DashboardOverview {
  const DashboardOverview({
    required this.tables,
    required this.reservationsToday,
    required this.ordersInProgress,
  });

  final TablesOverview tables;
  final int reservationsToday;
  final int ordersInProgress;

  factory DashboardOverview.fromJson(Map<String, dynamic> j) {
    return DashboardOverview(
      tables: TablesOverview.fromJson(
        j['tables'] as Map<String, dynamic>,
      ),
      reservationsToday: (j['reservationsToday'] as num).toInt(),
      ordersInProgress: (j['ordersInProgress'] as num).toInt(),
    );
  }
}
