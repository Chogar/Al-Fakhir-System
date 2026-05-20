import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/finance_period.dart';
import '../../core/permissions.dart';
import '../../data/models/finance_summary_model.dart';
import '../../l10n/app_strings.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key, required this.api, required this.user});

  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool _loading = true;
  String? _error;
  FinanceSummaryDto? _summary;
  List<Map<String, dynamic>> _expenses = [];
  FinancePeriod _period = FinancePeriod.month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!userCanViewFinance(widget.user)) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = {'period': financePeriodApiValue(_period)};
      final summaryRes = await widget.api.dio.get<Map<String, dynamic>>(
        '/dashboard/finance-summary',
        queryParameters: query,
      );
      final summary = FinanceSummaryDto.fromJson(summaryRes.data!);

      final expRes = await widget.api.dio.get<List<dynamic>>(
        '/expenses',
        queryParameters: {
          'spentOnFrom': summary.periodFrom,
          'spentOnTo': summary.periodTo,
        },
      );

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _expenses = expRes.data!
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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

  Future<void> _addExpense() async {
    final str = AppStrings.of(context);
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    DateTime spentOn = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return AlertDialog(
            title: Text(str.financeAddExpense),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelCtrl,
                    decoration:
                        InputDecoration(labelText: str.financeExpenseLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: str.financeExpenseAmount),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryCtrl,
                    decoration: InputDecoration(
                      labelText: str.financeExpenseCategory,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(str.financeExpenseDate),
                    subtitle: Text(toIsoDateOnly(spentOn)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: spentOn,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setModal(() => spentOn = d);
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
                child: Text(str.financeSaveExpense),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) return;
    final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
    if (labelCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;

    try {
      await widget.api.dio.post('/expenses', data: {
        'label': labelCtrl.text.trim(),
        'amount': amount,
        'spentOn': spentOn.toIso8601String(),
        if (categoryCtrl.text.trim().isNotEmpty)
          'category': categoryCtrl.text.trim(),
      });
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingDioMessage(e, str))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!userCanViewFinance(widget.user)) {
      return Center(child: Text(str.financeNoAccess));
    }

    final summary = _summary;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            str.financePageTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            str.financePageSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _addExpense,
                      icon: const Icon(Icons.add),
                      label: Text(str.financeAddExpense),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SegmentedButton<FinancePeriod>(
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
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: Text(str.refresh),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (summary != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: ListTile(
                              leading: Icon(Icons.trending_up, color: cs.primary),
                              title: Text(str.homeRevenuePeriod),
                              subtitle: Text('${summary.revenuePeriodFcfa} FCFA'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: ListTile(
                              leading: Icon(Icons.money_off, color: cs.error),
                              title: Text(str.homeExpensesPeriod),
                              subtitle:
                                  Text('${summary.expensesPeriodFcfa} FCFA'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_expenses.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Text(str.financeNoExpenses)),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final e = _expenses[i];
                      final label = e['label']?.toString() ?? '—';
                      final amount = e['amount']?.toString() ?? '0';
                      final spent = e['spentOn']?.toString() ?? '';
                      final cat = e['category']?.toString();
                      return ListTile(
                        title: Text(label),
                        subtitle: Text(
                          cat != null && cat.isNotEmpty
                              ? '$spent · $cat'
                              : spent,
                        ),
                        trailing: Text(
                          '$amount FCFA',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                    childCount: _expenses.length,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
