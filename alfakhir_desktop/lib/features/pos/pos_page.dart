import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/api/product_image_uri.dart';
import '../../core/notifications/top_notifier.dart';
import '../../core/permissions.dart';
import '../../core/pos/order_payload_validator.dart';
import '../../core/pos/pos_session_store.dart';
import '../../core/printing/receipt_print_service.dart';
import '../../core/utils/product_sort.dart';
import '../../data/models/category_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../l10n/app_strings.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key, required this.api, this.user});

  final ApiClient api;
  final Map<String, dynamic>? user;

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  static const int _gridCrossAxisCount = 4;
  static const double _gridChildAspectRatio = 0.68;
  static const double _productFooterHeight = 62;

  int _segment = 1;
  bool _loading = true;
  String? _error;

  List<CategoryDto> _categories = [];
  List<ProductDto> _products = [];
  List<Map<String, dynamic>> _tables = [];
  List<OrderSummaryDto> _historyOrders = [];
  bool _historyLoading = false;
  bool _submittingOrder = false;

  String? _categorySlug;
  String _serviceType = 'DINE_IN';
  String? _tableId;
  final Map<String, int> _cart = {};
  final TextEditingController _searchCtrl = TextEditingController();

  bool get _viewAllOrders => userCanViewAllOrders(widget.user);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final catRes = await widget.api.dio.get<List<dynamic>>('/categories');
      final prodRes = await widget.api.dio.get<List<dynamic>>(
        '/products',
        queryParameters: const {'sort': 'bestseller'},
      );
      final tableRes = await widget.api.dio.get<List<dynamic>>('/tables');
      _categories = (catRes.data ?? [])
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList();
      _products = (prodRes.data ?? [])
          .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
          .where((p) => p.isAvailable)
          .toList();
      _tables = (tableRes.data ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        final str = AppStrings.of(context);
        sortProductsAlphabetically(_products, preferArabic: str.isAr);
      }
      if (_segment == 2) await _loadHistory();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = userFacingDioMessage(e, AppStrings.of(context)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final from = PosSessionStore.toApiFrom(await PosSessionStore.shiftStartedAt());
      final res = await widget.api.dio.get<List<dynamic>>(
        '/orders/history',
        queryParameters: {'from': from},
      );
      _historyOrders = (res.data ?? [])
          .map((e) => OrderSummaryDto.fromJson(e as Map<String, dynamic>))
          .where((o) => o.status == 'PAID')
          .toList();
    } catch (_) {
      _historyOrders = [];
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  double get _sessionRevenue {
    var sum = 0.0;
    for (final o in _historyOrders) {
      sum += double.tryParse(o.totalFcfa.replaceAll(',', '.')) ?? 0;
    }
    return sum;
  }

  Future<void> _performDecaissement() async {
    final str = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(str.posDecaissementTitle),
        content: Text(str.posDecaissementConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(str.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(str.posDecaissement),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final from = PosSessionStore.toApiFrom(await PosSessionStore.shiftStartedAt());
      final decRes = await widget.api.dio.post<Map<String, dynamic>>(
        '/orders/decaissement',
        queryParameters: {'from': from},
      );
      final deleted = decRes.data?['deletedCount'];
      await PosSessionStore.resetShift();
      await openCashDrawerAfterSale();
      await _loadHistory();
      if (!mounted) return;
      final msg = deleted != null
          ? '${str.posDecaissementDone} ($deleted ${str.posSessionOrders})'
          : str.posDecaissementDone;
      TopNotifier.success(context, msg);
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, '$e');
    }
  }

  List<ProductDto> get _filteredProducts {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _products.where((p) {
      if (_categorySlug != null && p.categorySlug != _categorySlug) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.nameAr?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  double get _cartTotal {
    var sum = 0.0;
    for (final e in _cart.entries) {
      final p = _products.where((x) => x.id == e.key).firstOrNull;
      if (p == null) continue;
      final price = double.tryParse(p.price.replaceAll(',', '.')) ?? 0;
      sum += price * e.value;
    }
    return sum;
  }

  void _addToCart(ProductDto p) {
    setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1);
  }

  String _formatFcfa(double v) {
    final s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    return '$s FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(str.posTitle, style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 1, label: Text(str.posSegmentNew)),
              ButtonSegment(
                value: 2,
                label: Text(str.posSegmentHistoryScoped(_viewAllOrders)),
              ),
            ],
            selected: {_segment},
            onSelectionChanged: (s) async {
              setState(() => _segment = s.first);
              if (_segment == 2) await _loadHistory();
            },
          ),
        ),
        Expanded(
          child: _segment == 1 ? _buildSaleView(str, cs) : _buildHistoryView(str),
        ),
      ],
    );
  }

  Widget _buildSaleView(AppStrings str, ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _refresh, child: Text(str.refresh)),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _categorySlug,
                        decoration: InputDecoration(
                          labelText: str.posCategoryLabel,
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(str.posCategoryAll),
                          ),
                          for (final c in _categories)
                            DropdownMenuItem(
                              value: c.slug,
                              child: Text(c.label(preferArabic: str.isAr)),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categorySlug = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Rechercher…',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildProductGrid(str, cs)),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        SizedBox(width: 320, child: _buildCartPanel(str, cs)),
      ],
    );
  }

  Widget _buildProductGrid(AppStrings str, ColorScheme cs) {
    final items = _filteredProducts;
    if (items.isEmpty) {
      return Center(child: Text(str.posCartEmpty));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        childAspectRatio: _gridChildAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ProductCard(
        product: items[i],
        preferArabic: str.isAr,
        footerHeight: _productFooterHeight,
        onTap: () => _addToCart(items[i]),
      ),
    );
  }

  Widget _buildCartPanel(AppStrings str, ColorScheme cs) {
    final lines = [
      for (final e in _cart.entries)
        if (e.value > 0)
          _CartLine(
            product: _products.firstWhere((p) => p.id == e.key),
            qty: e.value,
            preferArabic: str.isAr,
            onRemove: () => setState(() {
              final n = (_cart[e.key] ?? 1) - 1;
              if (n <= 0) {
                _cart.remove(e.key);
              } else {
                _cart[e.key] = n;
              }
            }),
          ),
    ];

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket_outlined),
                const SizedBox(width: 8),
                Text(str.posCartTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: lines.isEmpty
                  ? Center(
                      child: Text(
                        str.posCartHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.outline,
                            ),
                      ),
                    )
                  : ListView(children: lines),
            ),
            Text(
              '${str.posTotal} : ${_formatFcfa(_cartTotal)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _serviceType,
              decoration: InputDecoration(labelText: str.posServiceType, isDense: true),
              items: [
                DropdownMenuItem(value: 'DINE_IN', child: Text(str.posServiceDineIn)),
                DropdownMenuItem(
                  value: 'TAKEAWAY',
                  child: Text(str.posServiceTakeaway),
                ),
              ],
              onChanged: (v) => setState(() => _serviceType = v ?? 'DINE_IN'),
            ),
            if (_serviceType == 'DINE_IN') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _tableId,
                decoration: InputDecoration(labelText: str.posTable, isDense: true),
                items: [
                  DropdownMenuItem(value: null, child: Text(str.posTableNone)),
                  for (final t in _tables)
                    DropdownMenuItem(
                      value: t['id']?.toString(),
                      child: Text(t['number']?.toString() ?? '—'),
                    ),
                ],
                onChanged: (v) => setState(() => _tableId = v),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submittingOrder ? null : _submitOrder,
              icon: _submittingOrder
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restaurant_menu),
              label: Text(_submittingOrder ? 'Traitement…' : str.posCreateOrder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView(AppStrings str) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          str.posSessionTotal,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatFcfa(_sessionRevenue)} · ${_historyOrders.length} ${str.posSessionOrders}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _historyLoading ? null : _performDecaissement,
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(str.posDecaissement),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_viewAllOrders)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              str.posHistoryScopedHint,
              style: theme.textTheme.bodySmall,
            ),
          ),
        Expanded(child: _historyBody(str)),
      ],
    );
  }

  Widget _historyBody(AppStrings str) {
    if (_historyLoading && _historyOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyOrders.isEmpty) {
      return Center(child: Text(str.statsNoData));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyOrders.length,
      itemBuilder: (_, i) {
        final o = _historyOrders[i];
        return ListTile(
          title: Text('${str.posOrderTitle} #${o.orderNumber}'),
          subtitle: Text(o.createdAt),
          trailing: Text('${o.totalFcfa} FCFA'),
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    final str = AppStrings.of(context);
    final issue = validateOrderPayload(
      cart: _cart,
      serviceType: _serviceType,
      tableId: _tableId,
    );
    if (issue != null) {
      final msg = issue.message == 'Ajoutez au moins un produit'
          ? str.posAddOneItem
          : issue.message;
      TopNotifier.warning(context, msg);
      return;
    }
    final items = buildOrderItems(_cart);
    final body = <String, dynamic>{
      'serviceType': _serviceType,
      'items': items,
      if (_tableId != null && _serviceType == 'DINE_IN') 'diningTableId': _tableId,
    };

    OrderDetailDto? created;
    setState(() => _submittingOrder = true);
    try {
      final createRes = await widget.api.dio.post<Map<String, dynamic>>(
        '/orders',
        data: body,
      );
      final data = createRes.data;
      if (data == null) throw StateError('Réponse commande vide');
      created = OrderDetailDto.fromJson(data);
      setState(() => _cart.clear());
      if (!mounted) return;
      await _showFinalizeAndPrintDialog(created);
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, '$e');
    } finally {
      if (mounted) setState(() => _submittingOrder = false);
    }
  }

  Future<void> _showFinalizeAndPrintDialog(OrderDetailDto order) async {
    final str = AppStrings.of(context);
    final subtotal =
        double.tryParse(order.totals.subtotal.replaceAll(',', '.')) ?? 0;
    final discountCtrl = TextEditingController(text: '0');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          final discount = double.tryParse(
                discountCtrl.text.trim().replaceAll(',', '.'),
              ) ??
              0;
          final valid = discount >= 0 && discount <= subtotal + 0.001;
          final total =
              (subtotal - discount.clamp(0, subtotal)).clamp(0, double.infinity)
                  .toDouble();
          return AlertDialog(
            title: Text('${str.posOrderTitle} #${order.orderNumber}'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(str.posTotal),
                      Text(_formatFcfa(subtotal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountCtrl,
                    decoration: InputDecoration(labelText: str.posDiscountOnTotal),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(str.posFinalTotal,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(_formatFcfa(total),
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  if (!valid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        str.posInvalidDiscount,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                onPressed: valid ? () => Navigator.pop(ctx, true) : null,
                icon: const Icon(Icons.print_outlined),
                label: Text(str.posConfirmAndPrint),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) {
      await _refresh(silent: true);
      if (mounted) TopNotifier.warning(context, str.posOrderSaved);
      return;
    }

    final parsed = double.tryParse(
          discountCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    final discount =
        parsed < 0 ? 0.0 : (parsed > subtotal ? subtotal : parsed);

    try {
      var settled = await _applyPaymentsWithDiscount(order, discount);
      final outcome = await printOrderReceipt(
        order: settled,
        restaurantName: str.appTitle,
        arabic: str.isAr,
        discountFcfa: discount,
      );
      final drawerOk = await openCashDrawerAfterSale();
      if (_segment == 2) await _loadHistory();
      await _refresh(silent: true);
      if (!mounted) return;
      switch (outcome) {
        case ReceiptPrintOutcome.printed:
          TopNotifier.success(
            context,
            drawerOk
                ? str.posOrderPaidPrinted
                : '${str.posOrderPaidPrinted} (${str.posDrawerFailed})',
          );
        case ReceiptPrintOutcome.cancelled:
          TopNotifier.warning(context, str.posOrderSavedPrintCancelled);
        case ReceiptPrintOutcome.failed:
          TopNotifier.warning(
            context,
            drawerOk ? str.posOrderSaved : '${str.posOrderSaved} — ${str.posDrawerFailed}',
          );
      }
    } on DioException catch (e) {
      if (mounted) TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (e) {
      if (mounted) TopNotifier.error(context, '$e');
    }
  }

  Future<OrderDetailDto> _applyPaymentsWithDiscount(
    OrderDetailDto order,
    double discountFcfa,
  ) async {
    final subtotal =
        double.tryParse(order.totals.subtotal.replaceAll(',', '.')) ?? 0;
    final discount = discountFcfa.clamp(0, subtotal);
    final cashAmount = subtotal - discount;
    var current = order;

    if (cashAmount > 0.009) {
      final payRes = await widget.api.dio.post<Map<String, dynamic>>(
        '/orders/${order.id}/payments',
        data: {'amount': cashAmount, 'method': 'CASH'},
      );
      if (payRes.data != null) {
        current = OrderDetailDto.fromJson(payRes.data!);
      }
    }
    if (discount > 0.009) {
      final remiseRes = await widget.api.dio.post<Map<String, dynamic>>(
        '/orders/${order.id}/payments',
        data: {'amount': discount, 'method': 'CASH', 'reference': 'REMISE'},
      );
      if (remiseRes.data != null) {
        current = OrderDetailDto.fromJson(remiseRes.data!);
      }
    }
    return current;
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.preferArabic,
    required this.footerHeight,
    required this.onTap,
  });

  final ProductDto product;
  final bool preferArabic;
  final double footerHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = product.displayName(preferArabic: preferArabic);
    final price = double.tryParse(product.price.replaceAll(',', '.')) ?? 0;
    final priceLabel =
        '${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)} FCFA';
    final imageUrl = productImageUri(product.imageUrl);

    return Material(
      color: cs.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(cs),
                    )
                  else
                    _imagePlaceholder(cs),
                  if (product.productNumber > 0)
                    PositionedDirectional(
                      top: 6,
                      start: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatProductNumber(product.productNumber),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: footerHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme cs) {
    return ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Icon(Icons.restaurant, color: cs.outline, size: 36),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.product,
    required this.qty,
    required this.preferArabic,
    required this.onRemove,
  });

  final ProductDto product;
  final int qty;
  final bool preferArabic;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(product.price.replaceAll(',', '.')) ?? 0;
    return ListTile(
      dense: true,
      title: Text(product.displayName(preferArabic: preferArabic)),
      subtitle: Text('x$qty · ${(price * qty).toStringAsFixed(0)} FCFA'),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: onRemove,
      ),
    );
  }
}
