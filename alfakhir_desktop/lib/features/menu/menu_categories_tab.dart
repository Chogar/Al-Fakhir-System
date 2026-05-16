import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../data/models/category_model.dart';
import '../../core/notifications/top_notifier.dart';
import '../../l10n/app_strings.dart';
/// CRUD catégories menu (slug technique + libellés).
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
      _items = (res.data ?? [])
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList();
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

  /// Génère un slug technique (MAJUSCULES, sans accents, underscores) à partir
  /// d'un libellé saisi par l'utilisateur. Utilisé uniquement à la création.
  String _slugFromLabel(String label) {
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ñ': 'n',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ý': 'y', 'ÿ': 'y',
    };
    var s = label.toLowerCase().trim();
    s = s.split('').map((c) => accents[c] ?? c).join();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'^_+|_+$'), '');
    s = s.toUpperCase();
    if (s.isEmpty) s = 'CAT';
    return s;
  }

  Future<void> _openEditor({CategoryDto? existing}) async {
    final str = AppStrings.of(context);
    final frCtrl = TextEditingController(text: existing?.labelFr ?? '');
    final arCtrl = TextEditingController(text: existing?.labelAr ?? '');
    final sortCtrl =
        TextEditingController(text: '${existing?.sortOrder ?? 0}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? str.menuCatNewTitle : str.menuCatEditTitle,
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: frCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: str.menuCatLabelFrField,
                    hintText: str.menuCatLabelHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: arCtrl,
                  decoration: InputDecoration(
                    labelText: str.menuCatLabelArField,
                    hintText: str.menuCatLabelArHint,
                  ),
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
    final labelArPayload =
        arTrim.isEmpty ? null : arTrim;

    try {
      if (existing == null) {
        // Slug auto à partir du libellé ; en cas de doublon le backend renvoie 409.
        var slug = _slugFromLabel(label);
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
        if (labelArPayload != null) {
          body['labelAr'] = labelArPayload;
        }
        await widget.api.dio.post('/categories', data: body);
      } else {
        // À l'édition, on ne touche pas au slug (préserve les liens produits).
        await widget.api.dio.patch('/categories/${existing.id}', data: {
          'labelFr': label,
          'sortOrder': sort,
          'labelAr': labelArPayload,
        });
      }
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.menuCatSaved);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.menuCatErrorGeneric,
      );
    }
  }

  Future<void> _delete(CategoryDto c) async {
    final str = AppStrings.of(context);
    if (c.productCount > 0) {
      await _openMergeDialog(c);
      return;
    }
    final display =
        categoryPickerLabel(c, _items, preferArabic: str.isAr);
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
      if (mounted) {
        TopNotifier.success(context, str.menuCatDeleted);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.menuCatErrorGeneric,
      );
    }
  }

  Future<void> _openMergeDialog(CategoryDto source) async {
    final str = AppStrings.of(context);
    final others = _items.where((c) => c.id != source.id).toList();
    if (others.isEmpty) {
      TopNotifier.warning(context, str.menuCatNoOtherCategory);
      return;
    }

    String targetId = others.first.id;
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
                  style: Theme.of(context).textTheme.bodyMedium,
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
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.menuCatErrorGeneric,
      );
    }
  }

  /// Ouvre un assistant qui interroge `/categories/duplicates` puis propose
  /// d'appliquer toutes les fusions suggérées en une seule action.
  Future<void> _openCleanupDialog() async {
    final str = AppStrings.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<_DuplicateGroup> groups;
    try {
      final res = await widget.api.dio.get<List<dynamic>>(
        '/categories/duplicates',
      );
      groups = (res.data ?? [])
          .map((e) => _DuplicateGroup.fromJson(e as Map<String, dynamic>))
          .where((g) => g.sources.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.menuCatErrorGeneric,
      );
      return;
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      TopNotifier.error(context, str.menuCatErrorColon(e));
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (groups.isEmpty) {
      TopNotifier.info(context, str.menuCatDedupNone);
      return;
    }

    final selected = <String>{
      for (final g in groups) ...g.sources.map((s) => s.id),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          final totalGroups = groups.length;
          final totalPairs = selected.length;
          return AlertDialog(
            title: Text(str.menuCatDedupTitle),
            content: SizedBox(
              width: 560,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      str.menuCatDedupOverview(totalGroups),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const Divider(height: 16),
                        itemBuilder: (_, gi) {
                          final g = groups[gi];
                          final targetLabel = categoryPickerLabel(
                            g.target,
                            _items,
                            preferArabic: str.isAr,
                            disambiguateWithSlug: true,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flag_outlined, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      str.menuCatDedupTargetCaption(
                                        targetLabel,
                                        g.target.slug,
                                        g.target.productCount,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              for (final s in g.sources)
                                CheckboxListTile(
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  value: selected.contains(s.id),
                                  onChanged: (v) {
                                    setLocal(() {
                                      if (v == true) {
                                        selected.add(s.id);
                                      } else {
                                        selected.remove(s.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    categoryPickerLabel(
                                      s,
                                      _items,
                                      preferArabic: str.isAr,
                                      disambiguateWithSlug: true,
                                    ),
                                  ),
                                  subtitle: Text(
                                    str.menuCatDedupProductsToMove(
                                      s.productCount,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      str.menuCatDedupSelectedCount(totalPairs),
                      style: Theme.of(context).textTheme.bodySmall,
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
              FilledButton.icon(
                onPressed: totalPairs == 0
                    ? null
                    : () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.merge_outlined),
                label: Text(str.menuCatMergeCount(totalPairs)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    final pairs = <Map<String, String>>[];
    for (final g in groups) {
      for (final s in g.sources) {
        if (selected.contains(s.id)) {
          pairs.add({'sourceId': s.id, 'targetId': g.target.id});
        }
      }
    }
    if (pairs.isEmpty) return;

    try {
      final res = await widget.api.dio.post<Map<String, dynamic>>(
        '/categories/merge-bulk',
        data: {'pairs': pairs},
      );
      await _refresh();
      if (!mounted) return;
      final applied = (res.data?['appliedCount'] as num?)?.toInt() ?? 0;
      final moved = (res.data?['movedProducts'] as num?)?.toInt() ?? 0;
      final errs = (res.data?['errors'] as List?)?.length ?? 0;
      TopNotifier.success(
        context,
        str.menuCatDedupSuccess(applied, moved, errs),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.menuCatErrorGeneric,
      );
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
            Text(_error!),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      str.menuCatPageTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openCleanupDialog,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: Text(str.menuCatDedupFab),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _refresh,
                      tooltip: str.refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  str.menuCatPageSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
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
                                  c.labelAr.trim().isEmpty
                                      ? '—'
                                      : c.labelAr,
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
                                      )
                                    else
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
            label: Text(str.menuCatFab),
          ),
        ),
      ],
    );
  }
}

/// Représentation locale d'un groupe doublons renvoyé par
/// `GET /categories/duplicates` : `{ target, sources, totalProducts }`.
class _DuplicateGroup {
  _DuplicateGroup({required this.target, required this.sources});

  final CategoryDto target;
  final List<CategoryDto> sources;

  factory _DuplicateGroup.fromJson(Map<String, dynamic> j) {
    return _DuplicateGroup(
      target: CategoryDto.fromJson(j['target'] as Map<String, dynamic>),
      sources: ((j['sources'] as List?) ?? const [])
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
