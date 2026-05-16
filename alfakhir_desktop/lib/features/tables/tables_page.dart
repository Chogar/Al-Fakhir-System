import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../data/models/dining_table_model.dart';

import '../../core/notifications/top_notifier.dart';
import '../../l10n/app_strings.dart';

const _kTypes = ['STANDARD', 'VIP', 'FAMILY'];
const _kStatuses = ['FREE', 'OCCUPIED', 'RESERVED', 'CLEANING'];

class TablesPage extends StatefulWidget {
  const TablesPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  List<DiningTableDto>? _tables;
  String? _error;
  bool _loading = true;

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.api.dio.get<List<dynamic>>('/tables');
      final list = (res.data ?? [])
          .map((e) => DiningTableDto.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _tables = list);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _openEditor({DiningTableDto? existing}) async {
    final str = AppStrings.of(context);
    final numCtrl = TextEditingController(
      text: existing != null ? '${existing.number}' : '',
    );
    final capCtrl = TextEditingController(
      text: existing != null ? '${existing.capacity}' : '4',
    );
    var type = existing?.tableType ?? 'STANDARD';
    var status = existing?.status ?? 'FREE';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            existing == null ? str.tablesNewTitle : str.tablesEditTitle,
          ),
          content: SizedBox(
            width: 400,
            child: StatefulBuilder(
              builder: (context, setLocal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: numCtrl,
                      decoration: InputDecoration(labelText: str.tablesFieldNumber),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capCtrl,
                      decoration: InputDecoration(labelText: str.tablesFieldCapacity),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: InputDecoration(labelText: str.tablesFieldType),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: type,
                          isExpanded: true,
                          items: _kTypes
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(str.tablesType(t)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setLocal(() => type = v ?? type),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: InputDecoration(labelText: str.tablesFieldStatus),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: status,
                          isExpanded: true,
                          items: _kStatuses
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(str.tablesStatus(t)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setLocal(() => status = v ?? status),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
        );
      },
    );

    if (ok != true || !mounted) return;

    final n = int.tryParse(numCtrl.text.trim());
    final cap = int.tryParse(capCtrl.text.trim());
    if (n == null || cap == null) {
      TopNotifier.error(context, str.tablesInvalidNumCap);
      return;
    }

    final dto = DiningTableDto(
      id: existing?.id ?? '',
      number: n,
      capacity: cap,
      tableType: type,
      status: status,
    );

    try {
      if (existing == null) {
        await widget.api.dio.post('/tables', data: dto.toCreateBody(status: status));
      } else {
        await widget.api.dio.patch('/tables/${existing.id}', data: dto.toPatchBody());
      }
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.tablesSaved);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.tablesErrGeneric,
      );
    }
  }

  Future<void> _delete(DiningTableDto t) async {
    final str = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(str.tablesDeleteTitle),
        content: Text(str.tablesDeleteBody(t.number)),
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
      await widget.api.dio.delete('/tables/${t.id}');
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.tablesDeleted);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.tablesErrGeneric,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    if (_loading && _tables == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _tables == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            FilledButton(onPressed: _refresh, child: Text(str.retry)),
          ],
        ),
      );
    }

    final rows = _tables ?? [];

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      str.tablesPageTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: str.refresh,
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(str.tablesColNo)),
                        DataColumn(label: Text(str.tablesColCapacity)),
                        DataColumn(label: Text(str.tablesColType)),
                        DataColumn(label: Text(str.tablesColStatus)),
                        const DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final t in rows)
                          DataRow(
                            cells: [
                              DataCell(Text('${t.number}')),
                              DataCell(Text('${t.capacity}')),
                              DataCell(Text(str.tablesType(t.tableType))),
                              DataCell(Text(str.tablesStatus(t.status))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: str.menuProdTooltipEdit,
                                      onPressed: () => _openEditor(existing: t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: str.menuProdTooltipDelete,
                                      onPressed: () => _delete(t),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 32,
          bottom: 32,
          child: FloatingActionButton.extended(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: Text(str.tablesFab),
          ),
        ),
      ],
    );
  }
}
