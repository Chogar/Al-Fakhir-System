import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/notifications/top_notifier.dart';
import '../../data/models/category_model.dart';
import '../../l10n/app_strings.dart';
import 'menu_ui.dart';

/// CRUD catégories menu (slug auto à la création, fusion si produits liés).
class MenuCategoriesTab extends StatefulWidget {
  const MenuCategoriesTab({super.key, required this.api});

  final ApiClient api;

  @override
  State<MenuCategoriesTab> createState() => _MenuCategoriesTabState();
}

class _MenuCategoriesTabState extends State<MenuCategoriesTab> {
  List<CategoryDto> _items = [];
  String? _error;
  bool _loading = true;

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.api.dio.get<List<dynamic>>('/categories');
      _items = dedupeCategoriesForMenu(
        (res.data ?? [])
            .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      if (mounted) {
        _error = userFacingDioMessage(e, AppStrings.of(context));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _openEditor({CategoryDto? existing}) async {
    final str = AppStrings.of(context);
    final frCtrl = TextEditingController(text: existing?.labelFr ?? '');
    final arCtrl = TextEditingController(text: existing?.labelAr ?? '');
    final sortCtrl = TextEditingController(text: '${existing?.sortOrder ?? 0}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? str.menuCatNewTitle : str.menuCatEditTitle,
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existing != null) ...[
                  InputDecorator(
                    decoration: InputDecoration(labelText: str.menuCatColSlug),
                    child: Text(
                      existing.slug,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: frCtrl,
                  autofocus: true,
                  decoration: InputDecoration(labelText: str.menuCatLabelFrField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: arCtrl,
                  decoration: InputDecoration(labelText: str.menuCatLabelArField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sortCtrl,
                  decoration: InputDecoration(labelText: str.menuCatSortField),
                  keyboardType: TextInputType.number,
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

    final label = frCtrl.text.trim();
    if (label.length < 2) {
      TopNotifier.error(context, str.menuCatLabelRequired);
      return;
    }
    final sort = int.tryParse(sortCtrl.text.trim());
    if (sort == null || sort < 0) {
      TopNotifier.error(context, str.menuCatSortInvalid);
      return;
    }
    final arTrim = arCtrl.text.trim();
    final labelArPayload = arTrim.isEmpty ? null : arTrim;

    setState(() => _loading = true);
    try {
      if (existing == null) {
        var slug = categorySlugFromLabel(label);
        final taken = _items.map((c) => c.slug).toSet();
        if (taken.contains(slug)) {
          var i = 2;
          while (taken.contains('${slug}_$i')) {
            i++;
          }
          slug = '${slug}_$i';
        }
        final body = <String, dynamic>{
          'slug': slug,
          'labelFr': label,
          'sortOrder': sort,
        };
        if (labelArPayload != null) body['labelAr'] = labelArPayload;
        await widget.api.dio.post('/categories', data: body);
      } else {
        await widget.api.dio.patch('/categories/${existing.id}', data: {
          'labelFr': label,
          'sortOrder': sort,
          'labelAr': labelArPayload,
        });
      }
      await _refresh();
      if (mounted) TopNotifier.success(context, str.menuCatSaved);
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMergeDialog(CategoryDto source) async {
    final str = AppStrings.of(context);
    final others = _items.where((c) => c.id != source.id).toList();
    if (others.isEmpty) {
      TopNotifier.warning(context, str.menuCatNoOtherCategory);
      return;
    }

    var targetId = others.first.id;
    final sourceDisplay =
        categoryPickerLabel(source, _items, preferArabic: str.isAr);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(str.menuCatMergeTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  str.menuCatMergeSourceIntro(
                        sourceDisplay,
                        source.slug,
                        source.productCount,
                      ) +
                      str.menuCatMergeBody,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(labelText: str.menuCatMergeInto),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: targetId,
                      isExpanded: true,
                      items: [
                        for (final o in others)
                          DropdownMenuItem(
                            value: o.id,
                            child: Text(
                              categoryPickerLabel(
                                o,
                                _items,
                                preferArabic: str.isAr,
                                disambiguateWithSlug: true,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => targetId = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(str.cancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.merge_outlined),
              label: Text(str.menuCatMergeAction),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final res = await widget.api.dio.post<Map<String, dynamic>>(
        '/categories/${source.id}/merge-into/$targetId',
      );
      await _refresh();
      if (!mounted) return;
      final moved = (res.data?['movedCount'] as num?)?.toInt() ?? 0;
      TopNotifier.success(context, str.menuCatMergedMoved(moved));
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    }
  }

  Future<void> _delete(CategoryDto c) async {
    final str = AppStrings.of(context);
    if (c.productCount > 0) {
      await _openMergeDialog(c);
      return;
    }

    final display = categoryPickerLabel(c, _items, preferArabic: str.isAr);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(str.menuCatDeleteTitle),
        content: Text(display),
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
      await widget.api.dio.delete('/categories/${c.id}');
      await _refresh();
      if (mounted) TopNotifier.success(context, str.menuCatDeleted);
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(onPressed: _refresh, child: Text(str.retry)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: _items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      str.isAr ? 'لا فئات' : 'Aucune catégorie',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : Card(
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: MenuUi.dataTableTheme(context),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(str.menuCatColSlug)),
                            DataColumn(label: Text(str.menuCatColLabelFr)),
                            DataColumn(label: Text(str.menuCatColLabelAr)),
                            DataColumn(label: Text(str.menuCatColOrder)),
                            DataColumn(label: Text(str.menuCatColProducts)),
                            const DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final c in _items)
                              DataRow(
                                cells: [
                                  DataCell(Text(c.slug)),
                                  DataCell(Text(c.labelFr)),
                                  DataCell(
                                    Text(
                                      (c.labelAr?.trim().isNotEmpty ?? false)
                                          ? c.labelAr!
                                          : '—',
                                    ),
                                  ),
                                  DataCell(Text('${c.sortOrder}')),
                                  DataCell(Text('${c.productCount}')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: str.menuCatTooltipEdit,
                                          onPressed: () => _openEditor(existing: c),
                                        ),
                                        if (c.productCount > 0)
                                          IconButton(
                                            icon: const Icon(Icons.merge_outlined),
                                            tooltip: str.menuCatTooltipMerge,
                                            onPressed: () => _openMergeDialog(c),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          tooltip: str.menuCatTooltipDelete,
                                          onPressed: () => _delete(c),
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
                  ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: Text(str.menuCatFab),
          ),
        ),
      ],
    );
  }
}
