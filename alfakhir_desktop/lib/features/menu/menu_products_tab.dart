import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/product_image_uri.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';

import '../../core/notifications/top_notifier.dart';
import '../../core/utils/product_sort.dart';
import '../../l10n/app_strings.dart';

class MenuProductsTab extends StatefulWidget {
  const MenuProductsTab({super.key, required this.api});

  final ApiClient api;

  @override
  State<MenuProductsTab> createState() => _MenuProductsTabState();
}

class _MenuProductsTabState extends State<MenuProductsTab> {
  List<CategoryDto> _categories = [];
  List<ProductDto> _products = [];
  String? _filterCategoryId;
  String? _error;
  bool _loading = true;

  Widget _productThumbnail(ProductDto p) {
    final uri = resolveProductImageUri(p.imageUrl, widget.api.dio.options.baseUrl);
    final outline = Theme.of(context).colorScheme.outline;
    if (uri == null) {
      return Icon(Icons.restaurant_outlined, size: 28, color: outline);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        uri.toString(),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: 26, color: outline),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catRes = await widget.api.dio.get<List<dynamic>>('/categories');
      _categories = dedupeCategoriesForMenu(
        (catRes.data ?? [])
            .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (_filterCategoryId != null &&
          !_categories.any((c) => c.id == _filterCategoryId)) {
        _filterCategoryId = null;
      }

      final prodRes = await widget.api.dio.get<List<dynamic>>(
        '/products',
        queryParameters: {
          if (_filterCategoryId != null) 'categoryId': _filterCategoryId!,
          'sort': 'alpha',
        },
      );
      _products = (prodRes.data ?? [])
          .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        final str = AppStrings.of(context);
        sortProductsAlphabetically(_products, preferArabic: str.isAr);
      }
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

  Future<String?> _uploadProductImage(String filePath, String filename) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final res = await widget.api.dio.post<Map<String, dynamic>>(
      '/products/upload-image',
      data: formData,
    );
    final url = res.data?['url'];
    return url is String ? url : null;
  }

  Future<void> _openEditor({ProductDto? existing}) async {
    final str = AppStrings.of(context);
    if (_categories.isEmpty) {
      if (mounted) {
        TopNotifier.warning(context, str.menuProdNoCategoriesSeed);
      }
      return;
    }

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final nameArCtrl = TextEditingController(text: existing?.nameAr ?? '');
    final priceCtrl = TextEditingController(text: existing?.price ?? '');
    final stockCtrl = TextEditingController(
      text: existing?.stockQuantity?.toString() ?? '',
    );
    final alertCtrl = TextEditingController(
      text: '${existing?.stockAlertThreshold ?? 0}',
    );
    var trackStock = existing?.tracksStock ?? false;
    var categoryId = existing?.category.id ?? _categories.first.id;
    var available = existing?.isAvailable ?? true;
    String? pickedImagePath;
    String? pickedImageLabel;
    var removeImage = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null ? str.menuProdNewTitle : str.menuProdEditTitle,
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (existing != null && existing.productNumber > 0) ...[
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: str.menuProdNumberLabel,
                          ),
                          child: Text(
                            formatProductNumber(existing.productNumber),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: str.menuProdCategoryField,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: categoryId,
                            isExpanded: true,
                            items: [
                              for (final c in _categories)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    categoryPickerLabel(
                                      c,
                                      _categories,
                                      preferArabic: str.isAr,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) setLocal(() => categoryId = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: str.menuProdNameField,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameArCtrl,
                        decoration: InputDecoration(
                          labelText: str.menuProdNameArField,
                          hintText: str.menuProdNameArHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceCtrl,
                        decoration: InputDecoration(
                          labelText: str.menuProdPriceField,
                          hintText: str.menuProdPriceHint,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final r = await FilePicker.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );
                            if (!ctx.mounted) return;
                            if (r != null && r.files.isNotEmpty) {
                              final f = r.files.single;
                              final path = f.path;
                              if (path != null && path.isNotEmpty) {
                                setLocal(() {
                                  pickedImagePath = path;
                                  pickedImageLabel = f.name;
                                  removeImage = false;
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(str.menuProdPickImage),
                        ),
                      ),
                      if (pickedImageLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          pickedImageLabel!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ] else if (!removeImage &&
                          (existing?.imageUrl ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          str.menuProdImageKept,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                      if (pickedImagePath != null ||
                          (!removeImage &&
                              (existing?.imageUrl ?? '').trim().isNotEmpty))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => setLocal(() {
                              removeImage = true;
                              pickedImagePath = null;
                              pickedImageLabel = null;
                            }),
                            child: Text(str.menuProdRemoveImage),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(str.menuProdAvailable),
                        value: available,
                        onChanged: (v) => setLocal(() => available = v),
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        title: Text(str.menuProdTrackStock),
                        subtitle: Text(str.menuProdTrackStockSubtitle),
                        value: trackStock,
                        onChanged: (v) {
                          setLocal(() {
                            trackStock = v;
                            if (v && stockCtrl.text.trim().isEmpty) {
                              stockCtrl.text = '0';
                            }
                          });
                        },
                      ),
                      if (trackStock) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: stockCtrl,
                          decoration: InputDecoration(
                            labelText: str.menuProdStockQty,
                            hintText: str.menuProdStockQtyHint,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: alertCtrl,
                          decoration: InputDecoration(
                            labelText: str.menuProdAlertThreshold,
                            hintText: str.menuProdAlertHint,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
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
            );
          },
        );
      },
    );

    if (ok != true || !mounted) return;

    final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
    if (price == null || price < 0) {
      TopNotifier.error(context, str.menuProdInvalidPrice);
      return;
    }

    String? imageUrlField;
    try {
      if (pickedImagePath != null) {
        final path = pickedImagePath!;
        if (!File(path).existsSync()) {
          if (!mounted) return;
          TopNotifier.error(context, str.menuProdImageNotFound);
          return;
        }
        final uploaded =
            await _uploadProductImage(path, pickedImageLabel ?? 'image.jpg');
        if (uploaded == null || uploaded.isEmpty) {
          if (!mounted) return;
          TopNotifier.error(context, str.menuProdUploadFail);
          return;
        }
        imageUrlField = uploaded;
      } else if (removeImage && existing != null) {
        imageUrlField = '';
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, e.response?.data?.toString() ?? e.message ?? str.posErrorGeneric);
      return;
    }

    int? stockQty;
    if (trackStock) {
      stockQty = int.tryParse(stockCtrl.text.trim());
      if (stockQty == null) {
        if (!mounted) return;
        TopNotifier.error(context, str.menuProdInvalidStockQty);
        return;
      }
    }
    int alertThreshold =
        int.tryParse(alertCtrl.text.trim()) ?? 0;
    if (alertThreshold < 0) alertThreshold = 0;

    final nameArTrim = nameArCtrl.text.trim();
    final nameArPayload = nameArTrim.isEmpty ? null : nameArTrim;

    final body = <String, dynamic>{
      'categoryId': categoryId,
      'name': nameCtrl.text.trim(),
      'nameAr': nameArPayload,
      'price': price,
      'isAvailable': available,
      'stockQuantity': trackStock ? stockQty : null,
      'stockAlertThreshold': alertThreshold,
    };
    if (imageUrlField != null) {
      body['imageUrl'] = imageUrlField;
    }

    try {
      if (existing == null) {
        await widget.api.dio.post('/products', data: body);
      } else {
        await widget.api.dio.patch('/products/${existing.id}', data: body);
      }
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.menuProdSaved);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, e.response?.data?.toString() ?? e.message ?? str.posErrorGeneric);
    }
  }

  /// Ouvre un dialogue pour ajuster manuellement le stock d'un produit.
  /// Le delta peut être positif (entrée, achat, retour) ou négatif (perte, casse,
  /// inventaire à la baisse). Le motif est optionnel et libre.
  Future<void> _adjustStock(ProductDto p) async {
    final str = AppStrings.of(context);
    final amtCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    var direction = 'in';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(str.menuProdAdjustStockTitleNamed(
            p.displayName(preferArabic: str.isAr),
          )),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (p.tracksStock)
                  Text(
                    str.menuProdStockCurrentVal(p.stockQuantity ?? 0),
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Text(
                    str.menuProdStockNotTrackedHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'in', label: Text(str.menuProdDirectionIn)),
                    ButtonSegment(value: 'out', label: Text(str.menuProdDirectionOut)),
                  ],
                  selected: {direction},
                  onSelectionChanged: (s) =>
                      setLocal(() => direction = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: str.menuProdQtyField,
                    hintText: str.menuProdStockQtyHint,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: str.menuProdReasonField,
                    hintText: str.menuProdReasonHint,
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
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(str.menuProdApply),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    final qty = int.tryParse(amtCtrl.text.trim());
    if (qty == null || qty <= 0) {
      TopNotifier.error(context, str.menuProdInvalidQty);
      return;
    }
    final delta = direction == 'in' ? qty : -qty;
    try {
      await widget.api.dio.post(
        '/products/${p.id}/stock-adjust',
        data: {
          'delta': delta,
          if (reasonCtrl.text.trim().isNotEmpty) 'reason': reasonCtrl.text.trim(),
        },
      );
      await _refresh();
      if (!mounted) return;
      TopNotifier.success(
        context,
        str.menuProdStockAdjustedVal('${delta > 0 ? '+' : ''}$delta'),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.posErrorGeneric,
      );
    }
  }

  Widget _stockCell(ProductDto p) {
    final str = AppStrings.of(context);
    if (!p.tracksStock) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      );
    }
    Color color;
    String label;
    if (p.isOutOfStock) {
      color = Colors.red.shade700;
      label = str.menuProdRupture;
    } else if (p.isLowStock) {
      color = Colors.orange.shade800;
      label = str.posLowStock;
    } else {
      color = Colors.green.shade700;
      label = str.menuProdStockOk;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${p.stockQuantity}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  /// Change la catégorie d'un produit en un clic via `PATCH /products/:id`.
  Future<void> _changeCategory(ProductDto p, String newCategoryId) async {
    final str = AppStrings.of(context);
    if (newCategoryId == p.category.id) return;
    try {
      await widget.api.dio.patch('/products/${p.id}', data: {
        'categoryId': newCategoryId,
      });
      await _refresh();
      if (mounted) {
        final cat = _categories.firstWhere(
          (c) => c.id == newCategoryId,
          orElse: () => p.category,
        );
        final catLabel =
            categoryPickerLabel(cat, _categories, preferArabic: str.isAr);
        TopNotifier.success(
          context,
          str.menuProdCategoryChangedNamed(
            p.displayName(preferArabic: str.isAr),
            catLabel,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.posErrorGeneric,
      );
    }
  }

  Widget _categoryCell(ProductDto p) {
    final str = AppStrings.of(context);
    final label = categoryPickerLabel(
      p.category,
      _categories,
      preferArabic: str.isAr,
    );
    return PopupMenuButton<String>(
      tooltip: str.menuProdChangeCategoryTooltip,
      onSelected: (v) => _changeCategory(p, v),
      itemBuilder: (_) => [
        for (final c in _categories)
          PopupMenuItem(
            value: c.id,
            child: Row(
              children: [
                if (c.id == p.category.id)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check, size: 16),
                  )
                else
                  const SizedBox(width: 22),
                Flexible(
                  child: Text(
                    categoryPickerLabel(c, _categories, preferArabic: str.isAr),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(ProductDto p) async {
    final str = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(str.menuProdDeleteTitle),
        content: Text(p.displayName(preferArabic: str.isAr)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(str.no)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(str.yes)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.api.dio.delete('/products/${p.id}');
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.menuProdDeleted);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, e.response?.data?.toString() ?? e.message ?? str.posErrorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    if (_loading && _products.isEmpty && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _products.isEmpty && _categories.isEmpty) {
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
                      str.menuProdPageTitle,
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
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: str.menuProdFilterCategory,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _filterCategoryId,
                      isExpanded: true,
                      hint: Text(str.menuProdAllCategoriesHint),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(str.allCategories),
                        ),
                        for (final c in _categories)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              categoryPickerLabel(
                                c,
                                _categories,
                                preferArabic: str.isAr,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() => _filterCategoryId = v);
                        _refresh();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(str.menuProdColPhoto)),
                        DataColumn(label: Text(str.menuProdColNumber)),
                        DataColumn(label: Text(str.menuProdColName)),
                        DataColumn(label: Text(str.menuProdColCategory)),
                        DataColumn(label: Text(str.menuProdColPrice)),
                        DataColumn(label: Text(str.menuProdColStock)),
                        DataColumn(label: Text(str.menuProdColAvailable)),
                        const DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final p in _products)
                          DataRow(
                            cells: [
                              DataCell(_productThumbnail(p)),
                              DataCell(Text(
                                formatProductNumber(p.productNumber),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              )),
                              DataCell(Text(
                                p.displayName(preferArabic: str.isAr),
                              )),
                              DataCell(_categoryCell(p)),
                              DataCell(Text('${p.price} FCFA')),
                              DataCell(_stockCell(p)),
                              DataCell(Icon(
                                p.isAvailable ? Icons.check_circle : Icons.cancel,
                                color: p.isAvailable ? Colors.green : Colors.grey,
                                size: 20,
                              )),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: str.menuProdTooltipAdjustStock,
                                      icon: const Icon(
                                          Icons.inventory_2_outlined),
                                      onPressed: () => _adjustStock(p),
                                    ),
                                    IconButton(
                                      tooltip: str.menuProdTooltipEdit,
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _openEditor(existing: p),
                                    ),
                                    IconButton(
                                      tooltip: str.menuProdTooltipDelete,
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(p),
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
            label: Text(str.menuProdFab),
          ),
        ),
      ],
    );
  }
}
