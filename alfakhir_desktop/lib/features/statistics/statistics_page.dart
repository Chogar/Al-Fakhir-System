import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/finance_period.dart';
import '../../data/models/sales_by_user_model.dart';
import '../../l10n/app_strings.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  SalesByUserReportDto? _report;
  bool _loading = true;
  String? _error;
  FinancePeriod _period = FinancePeriod.month;
  DateTime? _customFrom;
  DateTime? _customTo;

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
      final query = <String, dynamic>{};
      if (_period == FinancePeriod.custom &&
          _customFrom != null &&
          _customTo != null) {
        query['from'] = toIsoDateOnly(_customFrom!);
        query['to'] = toIsoDateOnly(_customTo!);
      } else {
        query['period'] = financePeriodApiValue(_period);
      }
      final res = await widget.api.dio.get<Map<String, dynamic>>(
        '/dashboard/sales-by-user',
        queryParameters: query,
      );
      if (!mounted) return;
      setState(() {
        _report = SalesByUserReportDto.fromJson(res.data!);
        _loading = false;
      });
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

  Future<void> _openCustomPeriodModal() async {
    final str = AppStrings.of(context);
    final now = DateTime.now();
    final locale = Locale(str.isAr ? 'ar' : 'fr');

    DateTime start =
        _customFrom ?? DateTime(now.year, now.month, now.day - 29);
    DateTime end = _customTo ?? DateTime(now.year, now.month, now.day);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return AlertDialog(
            title: Text(str.financeModalTitle),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(str.financeModalHint),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(str.financePickStart),
                    subtitle: Text(toIsoDateOnly(start)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: start,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1, 12, 31),
                        locale: locale,
                      );
                      if (d != null) setModal(() => start = d);
                    },
                  ),
                  ListTile(
                    title: Text(str.financePickEnd),
                    subtitle: Text(toIsoDateOnly(end)),
                    trailing: const Icon(Icons.event_outlined),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: end,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1, 12, 31),
                        locale: locale,
                      );
                      if (d != null) setModal(() => end = d);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(str.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(str.financeApplyRange),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) return;
    setState(() {
      final a = start;
      final b = end;
      _customFrom = a.isBefore(b) ? a : b;
      _customTo = a.isBefore(b) ? b : a;
      _period = FinancePeriod.custom;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final report = _report;

    return Scaffold(
      body: RefreshIndicator(
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
                      str.statsPageTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      str.statsPageSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SegmentedButton<FinancePeriod>(
                          segments: [
                            for (final p in FinancePeriod.values)
                              if (p != FinancePeriod.custom)
                                ButtonSegment<FinancePeriod>(
                                  value: p,
                                  label: Text(str.financePeriodSegmentCaption(p)),
                                ),
                          ],
                          selected: _period == FinancePeriod.custom
                              ? const <FinancePeriod>{}
                              : {_period},
                          onSelectionChanged: (sel) {
                            setState(() => _period = sel.first);
                            _load();
                          },
                        ),
                        OutlinedButton.icon(
                          onPressed: _openCustomPeriodModal,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(
                            _period == FinancePeriod.custom &&
                                    _customFrom != null &&
                                    _customTo != null
                                ? '${toIsoDateOnly(_customFrom!)} → ${toIsoDateOnly(_customTo!)}'
                                : str.financeCustomOpen,
                          ),
                        ),
                        if (_period == FinancePeriod.custom)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _period = FinancePeriod.month;
                                _customFrom = null;
                                _customTo = null;
                              });
                              _load();
                            },
                            child: Text(str.financeClearCustom),
                          ),
                      ],
                    ),
                    if (report != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${report.periodFrom} → ${report.periodTo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                        ),
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
            else if (report == null || report.users.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    str.statsNoData,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: str.statsTotalRevenue,
                          value: '${report.totalRevenueFcfa} FCFA',
                          icon: Icons.payments_outlined,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: str.statsTotalOrders,
                          value: '${report.totalOrders}',
                          icon: Icons.receipt_long_outlined,
                          color: cs.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  str.statsColUser,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  str.statsColOrders,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  str.statsColRevenue,
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 52,
                                child: Text(
                                  str.statsColShare,
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        for (var i = 0; i < report.users.length; i++) ...[
                          _UserSalesRow(
                            row: report.users[i],
                            rank: i + 1,
                            maxShare: report.users.first.share > 0
                                ? report.users.first.share
                                : 1,
                          ),
                          if (i < report.users.length - 1)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSalesRow extends StatelessWidget {
  const _UserSalesRow({
    required this.row,
    required this.rank,
    required this.maxShare,
  });

  final SalesByUserRowDto row;
  final int rank;
  final double maxShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final str = AppStrings.of(context);
    final sharePct = (row.share * 100).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  '$rank',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (row.username != null && row.username!.isNotEmpty)
                      Text(
                        str.statsRoleHint(row.username!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  '${row.orderCount}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${row.revenueFcfa} FCFA',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${sharePct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maxShare > 0 ? row.share / maxShare : 0,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
