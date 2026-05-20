import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/notifications/top_notifier.dart';
import '../../l10n/app_strings.dart';

class TablesPage extends StatefulWidget {
  const TablesPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tables = [];

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.api.dio.get<List<dynamic>>('/tables');
      _tables = (res.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (!mounted) return;
      _error = userFacingDioMessage(e, AppStrings.of(context));
    } catch (e) {
      if (!mounted) return;
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTable() async {
    final str = AppStrings.of(context);
    final numberCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4');
    String tableType = 'STANDARD';
    String status = 'FREE';

    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(str.navTables),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de table',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Capacité',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tableType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'STANDARD', child: Text('Standard')),
                      DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                      DropdownMenuItem(value: 'FAMILY', child: Text('Famille')),
                    ],
                    onChanged: (v) => setLocal(() => tableType = v ?? 'STANDARD'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'FREE', child: Text('Libre')),
                      DropdownMenuItem(value: 'OCCUPIED', child: Text('Occupée')),
                      DropdownMenuItem(value: 'RESERVED', child: Text('Réservée')),
                      DropdownMenuItem(value: 'CLEANING', child: Text('Nettoyage')),
                    ],
                    onChanged: (v) => setLocal(() => status = v ?? 'FREE'),
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
                child: const Text('Créer'),
              ),
            ],
          ),
        );
      },
    );

    if (submit != true) return;
    final number = int.tryParse(numberCtrl.text.trim());
    final capacity = int.tryParse(capacityCtrl.text.trim());
    if (number == null || number <= 0 || capacity == null || capacity <= 0) {
      TopNotifier.warning(context, 'Numéro/capacité invalides');
      return;
    }

    try {
      await widget.api.dio.post<Map<String, dynamic>>(
        '/tables',
        data: {
          'number': number,
          'capacity': capacity,
          'tableType': tableType,
          'status': status,
        },
      );
      if (!mounted) return;
      TopNotifier.success(context, 'Table créée');
      await _loadTables();
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, AppStrings.of(context)));
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> table, String status) async {
    final id = table['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      await widget.api.dio.patch<Map<String, dynamic>>(
        '/tables/$id',
        data: {'status': status},
      );
      if (!mounted) return;
      await _loadTables();
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, AppStrings.of(context)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(onPressed: _loadTables, child: Text(str.refresh)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  str.navTables,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: _createTable,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle table'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _tables.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = _tables[i];
              final number = t['number']?.toString() ?? '—';
              final status = t['status']?.toString() ?? 'FREE';
              final capacity = t['capacity']?.toString() ?? '0';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.table_restaurant_outlined),
                  title: Text('Table $number'),
                  subtitle: Text('Capacité: $capacity · Type: ${t['tableType'] ?? 'STANDARD'}'),
                  trailing: DropdownButton<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'FREE', child: Text('Libre')),
                      DropdownMenuItem(value: 'OCCUPIED', child: Text('Occupée')),
                      DropdownMenuItem(value: 'RESERVED', child: Text('Réservée')),
                      DropdownMenuItem(value: 'CLEANING', child: Text('Nettoyage')),
                    ],
                    onChanged: (v) {
                      if (v == null || v == status) return;
                      _updateStatus(t, v);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
