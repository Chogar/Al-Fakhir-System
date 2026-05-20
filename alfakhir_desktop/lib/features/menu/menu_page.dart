import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/notifications/top_notifier.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../l10n/app_strings.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _loading = true;
  String? _error;
  List<CategoryDto> _categories = [];
  List<ProductDto> _products = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catRes = await widget.api.dio.get<List<dynamic>>('/categories');
      final prodRes = await widget.api.dio.get<List<dynamic>>('/products');
      _categories = (catRes.data ?? [])
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList();
      _products = (prodRes.data ?? [])
          .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (!mounted) return;
      _error = userFacingDioMessage(e, AppStrings.of(context));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCategory() async {
    final slugCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final labelArCtrl = TextEditingController();
    final sortCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: slugCtrl,
                decoration: const InputDecoration(labelText: 'Slug', isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Libellé (FR)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: labelArCtrl,
                decoration: const InputDecoration(
                  labelText: 'Libellé (AR, optionnel)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sortCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ordre',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.of(context).cancel),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    );
    if (ok != true) return;
    final slug = slugCtrl.text.trim().toUpperCase();
    final label = labelCtrl.text.trim();
    final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;
    if (slug.isEmpty || label.isEmpty) {
      TopNotifier.warning(context, 'Slug et libellé sont obligatoires');
      return;
    }
    try {
      await widget.api.dio.post<Map<String, dynamic>>(
        '/categories',
        data: {
          'slug': slug,
          'labelFr': label,
          'labelAr': labelArCtrl.text.trim().isEmpty ? null : labelArCtrl.text.trim(),
          'sortOrder': sort,
        },
      );
      if (!mounted) return;
      TopNotifier.success(context, 'Catégorie créée');
      await _refresh();
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, AppStrings.of(context)));
    }
  }

  Future<void> _createProduct() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? categoryId = _categories.isEmpty ? null : _categories.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nouveau produit'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom produit',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prix FCFA',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    isDense: true,
                  ),
                  items: [
                    for (final c in _categories)
                      DropdownMenuItem(value: c.id, child: Text(c.labelFr)),
                  ],
                  onChanged: (v) => setLocal(() => categoryId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final parsedPrice = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || parsedPrice == null || parsedPrice <= 0 || categoryId == null) {
      TopNotifier.warning(context, 'Nom, prix valide et catégorie sont obligatoires');
      return;
    }
    try {
      await widget.api.dio.post<Map<String, dynamic>>(
        '/products',
        data: {
          'name': name,
          'price': parsedPrice,
          'categoryId': categoryId,
          'isAvailable': true,
        },
      );
      if (!mounted) return;
      TopNotifier.success(context, 'Produit créé');
      await _refresh();
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
            FilledButton(onPressed: _refresh, child: Text(str.refresh)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(str.navMenu, style: Theme.of(context).textTheme.titleLarge),
              ),
              FilledButton.icon(
                onPressed: _createCategory,
                icon: const Icon(Icons.category_outlined),
                label: const Text('Catégorie'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _categories.isEmpty ? null : _createProduct,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Produit'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.label_outline),
                        title: Text(c.labelFr),
                        subtitle: Text('${c.slug} · ordre ${c.sortOrder}'),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Card(
                  margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _products.length,
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          p.isAvailable ? Icons.check_circle_outline : Icons.block_outlined,
                        ),
                        title: Text(p.name),
                        subtitle: Text('${p.price} FCFA'),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
