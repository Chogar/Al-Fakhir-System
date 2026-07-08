import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/api/product_image_uri.dart';
import '../../core/notifications/top_notifier.dart';
import '../../core/utils/product_sort.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../l10n/app_strings.dart';
import 'menu_ui.dart';

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

  CategoryDto? _categoryById(String? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _productThumbnail(ProductDto p) {
    final url = productImageUri(p.imageUrl);
    final outline = Theme.of(context).colorScheme.outline;
    if (url == null) {
      return Icon(Icons.restaurant_outlined, size: 28, color: outline);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
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
          'sort': 'category',
        },
      );
      _products = (prodRes.data ?? [])
          .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        final str = AppStrings.of(context);
        sortProductsByCategory(
          _products,
          categories: _categories,
          preferArabic: str.isAr,
        );
      }
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

  Future<String?> _uploadProductImage(String filePath, String filename) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final res = await widget.api.dio.post<Map<String, dynamic>>(
      '/products/upload-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final url = res.data?['url'];
    return url is String ? url : null;
  }

  Future<void> _pickProductImage(
    BuildContext ctx,
    void Function(void Function()) setLocal, {
    required void Function(String path, String name) onPicked,
  }) async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (!ctx.mounted) return;
    if (r != null && r.files.isNotEmpty) {
      final f = r.files.single;
      final path = f.path;
      if (path != null && path.isNotEmpty) {
        setLocal(() => onPicked(path, f.name));
      }
    }
  }

  Widget _productImagePickerTile({
    required BuildContext context,
    required AppStrings str,
    required String? pickedImagePath,
    required String? existingImageUrl,
    required bool removeImage,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final cs = Theme.of(context).colorScheme;
    final existingUrl = productImageUri(existingImageUrl);
    Widget preview;
    if (pickedImagePath != null) {
      preview = Image.file(
        File(pickedImagePath),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (!removeImage && existingUrl != null) {
      preview = Image.network(
        existingUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, size: 48, color: cs.outline),
      );
    } else {
      preview = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: cs.primary),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              str.menuProdTapToUpload,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          str.menuProdImageField,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPick,
                child: SizedBox(width: 120, height: 120, child: preview),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(
                      pickedImagePath != null || (!removeImage && existingUrl != null)
                          ? str.menuProdChangeImage
                          : str.menuProdPickImage,
                    ),
                  ),
                  if (pickedImagePath != null ||
                      (!removeImage && (existingImageUrl ?? '').trim().isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onRemove,
                      child: Text(str.menuProdRemoveImage),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _openEditor({ProductDto? existing}) async {
    final str = AppStrings.of(context);
    if (_categories.isEmpty) {
      TopNotifier.warning(context, str.menuProdNoCategoriesSeed);
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
    var categoryId = existing?.categoryId ?? _categories.first.id;
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
                      _productImagePickerTile(
                        context: context,
                        str: str,
                        pickedImagePath: pickedImagePath,
                        existingImageUrl: existing?.imageUrl,
                        removeImage: removeImage,
                        onPick: () => _pickProductImage(
                          ctx,
                          setLocal,
                          onPicked: (path, name) {
                            pickedImagePath = path;
                            pickedImageLabel = name;
                            removeImage = false;
                          },
                        ),
                        onRemove: () => setLocal(() {
                          removeImage = true;
                          pickedImagePath = null;
                          pickedImageLabel = null;
                        }),
                      ),
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
                        decoration: InputDecoration(labelText: str.menuProdNameField),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameArCtrl,
                        decoration:
                            InputDecoration(labelText: str.menuProdNameArField),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceCtrl,
                        decoration: InputDecoration(labelText: str.menuProdPriceField),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                      SwitchListTile(
                        title: Text(str.menuProdAvailable),
                        value: available,
                        onChanged: (v) => setLocal(() => available = v),
                      ),
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
                        TextField(
                          controller: stockCtrl,
                          decoration:
                              InputDecoration(labelText: str.menuProdStockQty),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: alertCtrl,
                          decoration: InputDecoration(
                            labelText: str.menuProdAlertThreshold,
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
        if (!File(pickedImagePath!).existsSync()) {
          TopNotifier.error(context, str.menuProdImageNotFound);
          return;
        }
        final uploaded = await _uploadProductImage(
          pickedImagePath!,
          pickedImageLabel ?? 'image.jpg',
        );
        if (uploaded == null || uploaded.isEmpty) {
          TopNotifier.error(context, str.menuProdUploadFail);
          return;
        }
        imageUrlField = uploaded;
      } else if (removeImage && existing != null) {
        imageUrlField = '';
      }
    } on DioException catch (e) {
      TopNotifier.error(context, userFacingDioMessage(e, str));
      return;
    }

    int? stockQty;
    if (trackStock) {
      stockQty = int.tryParse(stockCtrl.text.trim());
      if (stockQty == null) {
        TopNotifier.error(context, str.menuProdInvalidStockQty);
        return;
      }
    }
    var alertThreshold = int.tryParse(alertCtrl.text.trim()) ?? 0;
    if (alertThreshold < 0) alertThreshold = 0;

    final nameArTrim = nameArCtrl.text.trim();
    final body = <String, dynamic>{
      'categoryId': categoryId,
      'name': nameCtrl.text.trim(),
      'nameAr': nameArTrim.isEmpty ? null : nameArTrim,
      'price': price,
      'isAvailable': available,
      'stockQuantity': trackStock ? stockQty : null,
      'stockAlertThreshold': alertThreshold,
    };
    if (imageUrlField != null) body['imageUrl'] = imageUrlField;

    if (nameCtrl.text.trim().length < 2) {
      TopNotifier.warning(
        context,
        str.isAr
            ? 'الاسم يجب أن يحتوي على حرفين على الأقل'
            : 'Le nom doit contenir au moins 2 caractères',
      );
      return;
    }

    try {
      if (existing == null) {
        await widget.api.dio.post('/products', data: body);
      } else {
        await widget.api.dio.patch('/products/${existing.id}', data: body);
      }
      await _refresh();
      if (mounted) TopNotifier.success(context, str.menuProdSaved);
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    }
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
      if (mounted) TopNotifier.success(context, str.menuProdDeleted);
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    }
  }

  List<Widget> _groupedProductTiles() {
    final str = AppStrings.of(context);
    final out = <Widget>[];
    String? lastCategoryId;

    for (final p in _products) {
      final catId = p.categoryId ?? '';
      if (catId != lastCategoryId) {
        lastCategoryId = catId;
        final cat = _categoryById(catId);
        out.add(
          MenuUi.sectionHeader(
            context,
            cat != null
                ? categoryPickerLabel(cat, _categories, preferArabic: str.isAr)
                : str.menuProdNoCategory,
          ),
        );
      }
      out.add(_productListTile(p));
    }
    return out;
  }

  Widget _productListTile(ProductDto p) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cat = _categoryById(p.categoryId);
    final catLabel = cat != null
        ? categoryPickerLabel(cat, _categories, preferArabic: str.isAr)
        : str.menuProdNoCategory;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEditor(existing: p),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 52, height: 52, child: _productThumbnail(p)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          formatProductNumber(p.productNumber),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.displayName(preferArabic: str.isAr),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          p.isAvailable ? Icons.check_circle : Icons.cancel,
                          color: p.isAvailable ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$catLabel · ${p.price} FCFA',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    _stockCell(p),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openEditor(existing: p),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(str.menuProdBtnEdit),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => _delete(p),
                    icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                    label: Text(
                      str.menuProdBtnDelete,
                      style: TextStyle(color: cs.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    return Text(
      '${p.stockQuantity} · $label',
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: str.menuProdFilterCategory,
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _filterCategoryId,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(str.menuProdAllCategoriesHint),
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
                const SizedBox(height: 12),
                if (_products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      str.isAr ? 'لا منتجات' : 'Aucun produit',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      str.menuProdColActions,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  ..._groupedProductTiles(),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: _openEditor,
            icon: const Icon(Icons.add),
            label: Text(str.menuProdFab),
          ),
        ),
      ],
    );
  }
}
