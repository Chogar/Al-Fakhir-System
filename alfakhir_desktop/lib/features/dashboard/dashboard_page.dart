import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/finance_period.dart';
import '../../core/permissions.dart';
import '../../data/models/dashboard_overview_model.dart';
import '../../data/models/dashboard_sales_breakdown_model.dart';
import '../../data/models/finance_summary_model.dart';
import '../../data/models/my_sales_model.dart';
import '../../l10n/app_strings.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.api, required this.user});

  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String? _error;
  DashboardOverviewDto? _overview;
  FinanceSummaryDto? _finance;
  MySalesDto? _mySales;
  DashboardSalesBreakdownDto? _breakdown;
  FinancePeriod _period = FinancePeriod.month;

  bool get _canDashboard => userCanViewDashboard(widget.user);
  bool get _canFinance => userCanViewFinance(widget.user);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> _periodQuery() => {
        'period': financePeriodApiValue(_period),
      };

  Future<void> _load() async {
    if (!_canDashboard && !_canFinance) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final futures = <Future<void>>[];

      if (_canDashboard) {
        futures.add(
          widget.api.dio
              .get<Map<String, dynamic>>('/dashboard/overview')
              .then((res) {
            _overview = DashboardOverviewDto.fromJson(res.data!);
          }),
        );
        futures.add(
          widget.api.dio
              .get<Map<String, dynamic>>(
                '/dashboard/my-sales',
                queryParameters: {..._periodQuery(), 'limit': 5},
              )
              .then((res) {
            _mySales = MySalesDto.fromJson(res.data!);
          }),
        );
      }

      if (_canFinance) {
        futures.add(
          widget.api.dio
              .get<Map<String, dynamic>>(
                '/dashboard/finance-summary',
                queryParameters: _periodQuery(),
              )
              .then((res) {
            _finance = FinanceSummaryDto.fromJson(res.data!);
          }),
        );
        futures.add(
          widget.api.dio
              .get<Map<String, dynamic>>(
                '/dashboard/sales-breakdown',
                queryParameters: {..._periodQuery(), 'limit': 6},
              )
              .then((res) {
            _breakdown = DashboardSalesBreakdownDto.fromJson(res.data!);
          }),
        );
      }

      await Future.wait(futures);
      if (!mounted) return;
      setState(() => _loading = false);
    } on DioException catch (e) {
      if (!mounted) return;
      final str = AppStrings.of(context);
      setState(() {
        _error = userFacingDioMessage(e, str);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  static String _fcfa(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v == null) return '$raw FCFA';
    if (v == v.roundToDouble()) return '${v.toInt()} FCFA';
    return '${v.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!_canDashboard && !_canFinance) {
      return Center(child: Text(str.homeNoAccess));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    str.homeTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    str.homeSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (_canFinance) ...[
                    const SizedBox(height: 16),
                    SegmentedButton<FinancePeriod>(
                      segments: [
                        for (final p in FinancePeriod.values)
                          if (p != FinancePeriod.custom)
                            ButtonSegment<FinancePeriod>(
                              value: p,
                              label: Text(str.financePeriodSegmentCaption(p)),
                            ),
                      ],
                      selected: {_period},
                      onSelectionChanged: (sel) {
                        setState(() => _period = sel.first);
                        _load();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: cs.error),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: Text(str.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_overview != null) ...[
                    Text(
                      str.homeSectionTables,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeTablesTotal,
                            value: '${_overview!.tablesTotal}',
                            icon: Icons.table_restaurant_outlined,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeTablesFree,
                            value: '${_overview!.tablesFree}',
                            icon: Icons.check_circle_outline,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeTablesOccupied,
                            value: '${_overview!.tablesOccupied}',
                            icon: Icons.people_outline,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeOrdersInProgress,
                            value: '${_overview!.ordersInProgress}',
                            icon: Icons.receipt_long_outlined,
                            color: cs.tertiary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeReservationsToday,
                            value: '${_overview!.reservationsToday}',
                            icon: Icons.event_outlined,
                            color: cs.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeTablesReserved,
                            value: '${_overview!.tablesReserved}',
                            icon: Icons.bookmark_outline,
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_finance != null) ...[
                    Text(
                      str.homeSectionFinance,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_finance!.periodFrom} → ${_finance!.periodTo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeRevenueToday,
                            value: _fcfa(_finance!.revenueTodayFcfa),
                            icon: Icons.trending_up,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeExpensesToday,
                            value: _fcfa(_finance!.expensesTodayFcfa),
                            icon: Icons.trending_down,
                            color: cs.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeRevenuePeriod,
                            value: _fcfa(_finance!.revenuePeriodFcfa),
                            icon: Icons.calendar_month_outlined,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeExpensesPeriod,
                            value: _fcfa(_finance!.expensesPeriodFcfa),
                            icon: Icons.money_off_outlined,
                            color: cs.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_mySales != null && !_canFinance) ...[
                    Text(
                      str.homeSectionMySales,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeMyRevenueToday,
                            value: _fcfa(_mySales!.revenueTodayFcfa),
                            icon: Icons.payments_outlined,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeKpi(
                            title: str.homeMyOrdersToday,
                            value: '${_mySales!.orderCountToday}',
                            icon: Icons.shopping_bag_outlined,
                            color: cs.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_breakdown != null &&
                      _breakdown!.byCategory.isNotEmpty) ...[
                    Text(
                      str.homeSectionCategories,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          for (final row in _breakdown!.byCategory)
                            ListTile(
                              title: Text(row.categoryName),
                              subtitle: Text('${row.quantity} ${str.homeUnits}'),
                              trailing: Text(
                                '${(row.share * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_breakdown != null &&
                      _breakdown!.topProducts.isNotEmpty) ...[
                    Text(
                      str.homeSectionTopProducts,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          for (final row in _breakdown!.topProducts)
                            ListTile(
                              title: Text(row.name),
                              subtitle: Text('× ${row.quantity}'),
                              trailing: Text(
                                _fcfa(row.revenueFcfa),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeKpi extends StatelessWidget {
  const _HomeKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
