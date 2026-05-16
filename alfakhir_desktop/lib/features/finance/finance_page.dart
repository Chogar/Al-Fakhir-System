import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/finance_period.dart';
import '../../core/notifications/top_notifier.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/finance_summary_model.dart';
import '../../l10n/app_strings.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key, required this.api});

  final ApiClient api;

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  DashboardFinanceSummaryDto? _summary;
  List<ExpenseDto> _expenses = [];
  List<String> _categorySuggestions = [];

  FinancePeriod _period = FinancePeriod.month;
  DateTime? _customFrom;
  DateTime? _customTo;

  String? _error;
  bool _loading = true;

  (String fromIso, String toIso) _currentRangeIso() {
    if (_period == FinancePeriod.custom &&
        _customFrom != null &&
        _customTo != null) {
      final a = _customFrom!;
      final b = _customTo!;
      final start = a.isBefore(b) ? a : b;
      final end = a.isBefore(b) ? b : a;
      return (toIsoDateOnly(start), toIsoDateOnly(end));
    }
    final fallback =
        _period == FinancePeriod.custom ? FinancePeriod.month : _period;
    return isoRangeForExpenseFilter(fallback);
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final range = _currentRangeIso();

      final sumQuery = <String, dynamic>{};
      if (_period == FinancePeriod.custom) {
        sumQuery['from'] = range.$1;
        sumQuery['to'] = range.$2;
      } else {
        sumQuery['period'] = financePeriodApiValue(_period);
      }

      final sumRes = await widget.api.dio.get<Map<String, dynamic>>(
        '/dashboard/finance-summary',
        queryParameters: sumQuery,
      );

      final expRes = await widget.api.dio.get<List<dynamic>>(
        '/expenses',
        queryParameters: {
          'spentOnFrom': range.$1,
          'spentOnTo': range.$2,
        },
      );

      _summary = DashboardFinanceSummaryDto.fromJson(sumRes.data!);
      _expenses = (expRes.data ?? [])
          .map((e) => ExpenseDto.fromJson(e as Map<String, dynamic>))
          .toList();

      try {
        final catRes = await widget.api.dio.get<List<dynamic>>(
          '/expenses/categories',
        );
        _categorySuggestions = [
          for (final e in catRes.data ?? const [])
            if (e is Map<String, dynamic> && e['category'] != null)
              e['category'].toString(),
        ];
      } catch (_) {
        _categorySuggestions = [];
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Période personnalisée : **modal** avec choix début / fin puis application.
  Future<void> _openCustomPeriodModal() async {
    final str = AppStrings.of(context);
    final now = DateTime.now();
    final locale = str.isAr ? const Locale('ar') : const Locale('fr');

    DateTime start =
        _customFrom ?? DateTime(now.year, now.month, now.day - 6);
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
                  Text(
                    str.financeModalHint,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor:
                        Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    title: Text(str.financePickStart),
                    subtitle: Text(
                      toIsoDateOnly(start),
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
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
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor:
                        Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    title: Text(str.financePickEnd),
                    subtitle: Text(
                      toIsoDateOnly(end),
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
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
    _refresh();
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _openExpenseEditor({ExpenseDto? existing}) async {
    final str = AppStrings.of(context);
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final amtCtrl = TextEditingController(
      text: existing == null ? '' : existing.amount.replaceAll(',', '.'),
    );
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    final spentCtrl = TextEditingController(
      text: existing == null
          ? DateTime.now().toIso8601String().split('T').first
          : existing.spentOn.split('T').first,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? str.financeNewExpense : str.financeEditExpense,
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(labelText: str.financeLabelField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  decoration: InputDecoration(labelText: str.financeAmountField),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: spentCtrl,
                  decoration: InputDecoration(labelText: str.financeDateField),
                ),
                const SizedBox(height: 12),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: catCtrl.text),
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) return _categorySuggestions;
                    return _categorySuggestions.where(
                      (x) => x.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (v) => catCtrl.text = v,
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmitted) {
                    controller.text = catCtrl.text;
                    controller.selection = TextSelection.collapsed(
                      offset: controller.text.length,
                    );
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (v) => catCtrl.text = v,
                      decoration: InputDecoration(
                        labelText: str.financeCategoryField,
                        hintText: str.financeCategoryHint,
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final list = options.toList();
                    return Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Material(
                        elevation: 4,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 220,
                            maxWidth: 340,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final opt = list[i];
                              return ListTile(
                                dense: true,
                                title: Text(opt),
                                onTap: () => onSelected(opt),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(str.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(str.save),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final amt = double.tryParse(amtCtrl.text.trim().replaceAll(',', '.'));
    if (amt == null || amt <= 0) {
      TopNotifier.error(context, str.financeInvalidAmount);
      return;
    }

    final body = <String, dynamic>{
      'label': labelCtrl.text.trim(),
      'amount': amt,
      'spentOn': spentCtrl.text.trim(),
    };

    final rawCat = catCtrl.text.trim();
    if (existing != null) {
      body['category'] = rawCat.isEmpty ? '' : rawCat;
    } else if (rawCat.isNotEmpty) {
      body['category'] = rawCat;
    }

    try {
      if (existing == null) {
        await widget.api.dio.post('/expenses', data: body);
      } else {
        await widget.api.dio.patch('/expenses/${existing.id}', data: body);
      }
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.financeExpenseSaved);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
          context, e.response?.data?.toString() ?? e.message ?? '');
    }
  }

  Future<void> _deleteExpense(ExpenseDto e) async {
    final str = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(str.financeDeleteExpenseTitle),
        content: Text(e.label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(str.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(str.yes),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.api.dio.delete('/expenses/${e.id}');
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.financeDeleted);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
          context, e.response?.data?.toString() ?? e.message ?? '');
    }
  }

  String _periodKpiTitle(AppStrings str) => str.periodSubtitle(_period);

  String _filteredExpensesSubtitle(AppStrings str) {
    final r = _currentRangeIso();
    final cap = str.periodCaption(_period);
    if (str.isAr) {
      return 'الفترة: ${r.$1} ← ${r.$2}. ملخص ومصروفات لـ $cap؛ '
          'قائمة مفلترة حسب التاريخ (الأحدث أولاً).';
    }
    return 'Période : ${r.$1} → ${r.$2}. Encaissements et synthèses pour '
        '${cap.toLowerCase()} ; liste des dépenses filtrée, tri par date '
        'descendante.';
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);

    if (_loading && _summary == null && _expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _summary == null && _expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _refresh, child: Text(str.retry)),
          ],
        ),
      );
    }

    final summary = _summary;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          str.financeTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          str.financeSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: str.refresh,
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _filteredExpensesSubtitle(str),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<FinancePeriod>(
                    segments: [
                      for (final p in FinancePeriod.values)
                        if (p != FinancePeriod.custom)
                          ButtonSegment<FinancePeriod>(
                            value: p,
                            label: Text(str.periodCaption(p)),
                          ),
                    ],
                    selected: _period == FinancePeriod.custom
                        ? const <FinancePeriod>{}
                        : {_period},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      setState(() => _period = selection.first);
                      _refresh();
                    },
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _openCustomPeriodModal,
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      _period == FinancePeriod.custom &&
                              _customFrom != null &&
                              _customTo != null
                          ? '${toIsoDateOnly(_customFrom!)} → ${toIsoDateOnly(_customTo!)}'
                          : str.financeCustomOpen,
                    ),
                  ),
                  if (_period == FinancePeriod.custom)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _period = FinancePeriod.month;
                          _customFrom = null;
                          _customTo = null;
                        });
                        _refresh();
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: Text(str.financeClearCustom),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (summary != null)
                LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final cross = w > 900 ? 4 : (w > 520 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: cross,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: cross == 1 ? 2.8 : 1.35,
                      children: [
                        _MiniFinanceCard(
                          title: str.financeKpiTodayRevenue,
                          value: '${summary.revenueTodayFcfa} FCFA',
                          color: Colors.green.shade700,
                          icon: Icons.trending_up,
                        ),
                        _MiniFinanceCard(
                          title: str.financeKpiTodayExpenses,
                          value: '${summary.expensesTodayFcfa} FCFA',
                          color: Colors.red.shade700,
                          icon: Icons.trending_down,
                        ),
                        _MiniFinanceCard(
                          title:
                              '${str.financeKpiPeriodRevenue} (${_periodKpiTitle(str)})',
                          value: '${summary.revenuePeriodFcfa} FCFA',
                          color: AppColors.brandRed,
                          icon: Icons.calendar_month_outlined,
                        ),
                        _MiniFinanceCard(
                          title:
                              '${str.financeKpiPeriodExpenses} (${_periodKpiTitle(str)})',
                          value: '${summary.expensesPeriodFcfa} FCFA',
                          color: Colors.deepOrange.shade800,
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 28),
              Text(
                str.financeExpensesTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_expenses.isEmpty)
                Text(
                  str.financeNoExpenses,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                )
              else
                ..._expenses.map(
                  (e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(e.label),
                      subtitle: Text(
                        '${e.spentOn.split('T').first}'
                        '${e.category != null ? ' · ${e.category}' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${e.amount} FCFA',
                            style: theme.textTheme.titleSmall,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openExpenseEditor(existing: e),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteExpense(e),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        PositionedDirectional(
          end: 32,
          bottom: 32,
          child: FloatingActionButton.extended(
            onPressed: () => _openExpenseEditor(),
            icon: const Icon(Icons.add_rounded),
            label: Text(str.financeFabExpense),
          ),
        ),
      ],
    );
  }
}

class _MiniFinanceCard extends StatelessWidget {
  const _MiniFinanceCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              color.withValues(alpha: 0.06),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
