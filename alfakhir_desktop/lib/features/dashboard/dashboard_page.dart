import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/finance_period.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/models/finance_summary_model.dart';
import '../../data/models/sales_breakdown_model.dart';
import '../../l10n/app_strings.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardOverview? _data;
  DashboardFinanceSummaryDto? _finance;
  SalesBreakdownDto? _breakdown;
  FinancePeriod _breakdownPeriod = FinancePeriod.month;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.api.dio.get<Map<String, dynamic>>(
        '/dashboard/overview',
      );
      DashboardFinanceSummaryDto? fin;
      try {
        final fr = await widget.api.dio.get<Map<String, dynamic>>(
          '/dashboard/finance-summary',
          queryParameters: {'period': 'month'},
        );
        fin = DashboardFinanceSummaryDto.fromJson(fr.data!);
      } catch (_) {
        fin = null;
      }

      SalesBreakdownDto? breakdown;
      try {
        final br = await widget.api.dio.get<Map<String, dynamic>>(
          '/dashboard/sales-breakdown',
          queryParameters: {
            'period': financePeriodApiValue(_breakdownPeriod),
            'limit': 8,
          },
        );
        breakdown = SalesBreakdownDto.fromJson(br.data!);
      } catch (_) {
        breakdown = null;
      }

      setState(() {
        _data = DashboardOverview.fromJson(res.data!);
        _finance = fin;
        _breakdown = breakdown;
        _error = null;
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadBreakdown() async {
    try {
      final br = await widget.api.dio.get<Map<String, dynamic>>(
        '/dashboard/sales-breakdown',
        queryParameters: {
          'period': financePeriodApiValue(_breakdownPeriod),
          'limit': 8,
        },
      );
      if (!mounted) return;
      setState(() {
        _breakdown = SalesBreakdownDto.fromJson(br.data!);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _breakdown = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _load, child: Text(str.retry)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final d = _data!;
    final fin = _finance;
    final cs = Theme.of(context).colorScheme;

    final tiles = <_MetricSpec>[
      _MetricSpec(
        title: str.dashboardKpiTablesTitle,
        value: '${d.tables.total}',
        subtitle: str.dashboardKpiTablesSubtitle,
        icon: Icons.table_restaurant_rounded,
        accent: cs.primary,
      ),
      _MetricSpec(
        title: str.dashboardKpiOrdersTitle,
        value: '${d.ordersInProgress}',
        subtitle: str.dashboardKpiOrdersSubtitle,
        icon: Icons.restaurant_menu_rounded,
        accent: const Color(0xFF8B4513),
      ),
      if (fin != null) ...[
        _MetricSpec(
          title: str.dashboardKpiRevenueDayTitle,
          value: '${fin.revenueTodayFcfa} FCFA',
          subtitle: str.dashboardKpiRevenueDaySubtitle,
          icon: Icons.trending_up_rounded,
          accent: const Color(0xFF2E7D32),
        ),
        _MetricSpec(
          title: str.dashboardKpiExpensesDayTitle,
          value: '${fin.expensesTodayFcfa} FCFA',
          subtitle: str.dashboardKpiExpensesDaySubtitle,
          icon: Icons.trending_down_rounded,
          accent: const Color(0xFFC62828),
        ),
        _MetricSpec(
          title: str.dashboardRevenueKpiTitleForApiPeriod(fin.period),
          value: '${fin.revenuePeriodFcfa} FCFA',
          subtitle: str.dashboardKpiRevenuePeriodSubtitle,
          icon: Icons.calendar_month_rounded,
          accent: AppColors.brandRed,
        ),
        _MetricSpec(
          title: str.dashboardExpensesKpiTitleForApiPeriod(fin.period),
          value: '${fin.expensesPeriodFcfa} FCFA',
          subtitle: str.dashboardKpiExpensesPeriodSubtitle,
          icon: Icons.receipt_long_rounded,
          accent: const Color(0xFFE65100),
        ),
      ],
    ];

    return RefreshIndicator(
      onRefresh: _load,
      edgeOffset: 80,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: appPagePadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DashboardHero(
                  title: str.dashboardOverviewTitle,
                  subtitle: str.dashboardHeroSubtitle,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final n = tiles.length;
                    final cross = w > 900
                        ? (n >= 4 ? 4 : n)
                        : (w > 520 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: cross == 1 ? 2.8 : 1.35,
                      ),
                      itemCount: n,
                      itemBuilder: (_, i) => _MetricTile(spec: tiles[i]),
                    );
                  },
                ),
                const SizedBox(height: 36),
                _buildSalesBreakdownSection(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesBreakdownSection() {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    str.dashboardSalesStatsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    str.dashboardSalesStatsSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SegmentedButton<FinancePeriod>(
              segments: [
                for (final p in FinancePeriod.values)
                  if (p != FinancePeriod.custom)
                    ButtonSegment<FinancePeriod>(
                      value: p,
                      label: Text(str.financePeriodSegmentCaption(p)),
                    ),
              ],
              selected: {_breakdownPeriod},
              onSelectionChanged: (sel) {
                setState(() => _breakdownPeriod = sel.first);
                _reloadBreakdown();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_breakdown == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.insights_outlined, color: cs.outline, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      str.dashboardNoBreakdownData,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final twoCols = c.maxWidth > 760;
              final topCard = _buildTopProductsCard(_breakdown!);
              final catCard = _buildCategoryBreakdownCard(_breakdown!);
              if (twoCols) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: topCard),
                    const SizedBox(width: 16),
                    Expanded(child: catCard),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  topCard,
                  const SizedBox(height: 16),
                  catCard,
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildTopProductsCard(SalesBreakdownDto b) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionIcon(icon: Icons.workspace_premium_rounded, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    str.dashboardTopProductsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${b.totalUnits} ${str.dashboardUnitsAbbr} · ${b.totalRevenueFcfa} FCFA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (b.topProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  str.dashboardNoSalesPeriod,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                  ),
                ),
              )
            else
              for (var i = 0; i < b.topProducts.length; i++)
                _TopProductRow(rank: i + 1, p: b.topProducts[i]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(SalesBreakdownDto b) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionIcon(icon: Icons.pie_chart_rounded, color: cs.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    str.dashboardByCategoryTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${b.totalOrders} ${str.dashboardOrdersAbbr}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (b.byCategory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  str.dashboardCategoryEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                  ),
                ),
              )
            else
              for (final c in b.byCategory)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${(c.share * 100).toStringAsFixed(c.share < 0.1 ? 1 : 0)}%',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${c.revenueFcfa} FCFA',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: c.share.clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.brandRed.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface,
            cs.primaryContainer.withValues(alpha: 0.22),
            cs.surface,
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.88)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSpec {
  const _MetricSpec({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.spec});

  final _MetricSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              spec.accent.withValues(alpha: 0.06),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(spec.icon, color: spec.accent, size: 28),
            const SizedBox(height: 8),
            Text(
              spec.title,
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              spec.value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              spec.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.outline,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.rank, required this.p});

  final int rank;
  final TopProductDto p;

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final medal = rank <= 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: theme.textTheme.labelMedium?.copyWith(
                color: medal ? cs.primary : cs.outline,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${p.quantity} ${str.dashboardUnitsAbbr}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${p.revenueFcfa} FCFA',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
