import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/api/product_image_uri.dart';
import '../../core/finance_period.dart';
import '../../core/printing/receipt_pdf.dart';
import '../../core/printing/receipt_print_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/dining_table_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';

import '../../core/notifications/top_notifier.dart';
import '../../core/permissions.dart';
import '../../l10n/app_strings.dart';

const _serviceValues = ['DINE_IN', 'TAKEAWAY'];
const _statusValues = [
  'PLACED',
  'PREPARING',
  'READY',
  'SERVED',
  'PAID',
  'CANCELLED',
];
const _paymentValues = ['CASH', 'MOBILE_MONEY', 'BANK_CARD'];

class PosPage extends StatefulWidget {
  const PosPage({super.key, required this.api, this.user});

  final ApiClient api;
  final Map<String, dynamic>? user;

  @override
  State<PosPage> createState() => PosPageState();
}

class PosPageState extends State<PosPage> {
  /// Recharge catalogue, tables et commandes (ex. retour sur l’onglet Caisse).
  Future<void> reloadCatalogAndOrders() => _refresh(silent: true);
  List<CategoryDto> _categories = [];
  List<ProductDto> _products = [];
  List<DiningTableDto> _tables = [];
  List<OrderDetailDto> _historyOrders = [];

  final Map<String, int> _cart = {};

  String _serviceType = 'DINE_IN';
  String? _tableId;
  String? _categoryFilterId;

  String? _error;
  bool _loading = true;
  bool _historyLoading = false;
  int _segment = 0;

  DateTime? _historyFrom;
  DateTime? _historyTo;

  ProductDto? _productById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Ouvre la feuille d’impression système (ticket PDF).
  ///
  /// Sur macOS, une [AlertDialog] modale bloque souvent l’aperçu d’impression :
  /// si [dialogContext] est fourni, la boîte est d’abord fermée puis l’impression
  /// est lancée après un court délai.
  Future<ReceiptPrintOutcome> _printReceipt(
    OrderDetailDto order, {
    BuildContext? dialogContext,
    double discountFcfa = 0,
  }) async {
    if (dialogContext != null && Navigator.maybeOf(dialogContext)?.canPop() == true) {
      Navigator.of(dialogContext).pop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return ReceiptPrintOutcome.failed;
    final str = AppStrings.of(context);
    try {
      return await printOrderReceipt(
        order: order,
        restaurantName: str.appTitle,
        arabic: str.isAr,
        discountFcfa: discountFcfa,
      );
    } catch (e) {
      if (mounted) {
        TopNotifier.error(context, '${str.posPrintFail} : $e');
      }
      return ReceiptPrintOutcome.failed;
    }
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.payments_outlined;
      case 'MOBILE_MONEY':
        return Icons.phone_iphone;
      case 'BANK_CARD':
        return Icons.credit_card_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  double _cartTotalFcfa() {
    double sum = 0;
    for (final e in _cart.entries) {
      final p = _productById(e.key);
      if (p == null) continue;
      final unit = double.tryParse(p.price.replaceAll(',', '.')) ?? 0;
      sum += unit * e.value;
    }
    return sum;
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _error = null);
    }
    try {
      final catRes = await widget.api.dio.get<List<dynamic>>('/categories');
      _categories = dedupeCategoriesForMenu(
        (catRes.data ?? [])
            .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      final prodRes = await widget.api.dio.get<List<dynamic>>(
        '/products',
        queryParameters: const {'sort': 'bestseller'},
      );
      _products = (prodRes.data ?? [])
          .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
          .where((p) => p.isAvailable)
          .toList();

      final tblRes = await widget.api.dio.get<List<dynamic>>('/tables');
      _tables = (tblRes.data ?? [])
          .map((e) => DiningTableDto.fromJson(e as Map<String, dynamic>))
          .toList();

    } on DioException catch (e) {
      if (mounted) {
        final str = AppStrings.of(context);
        setState(() => _error = userFacingDioMessage(e, str));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        if (!silent) {
          setState(() => _loading = false);
        } else {
          setState(() {});
        }
        if (_segment == 1) {
          await _loadHistory();
        }
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final query = <String, dynamic>{};
      if (_historyFrom != null) {
        query['from'] = toIsoDateOnly(_historyFrom!);
      }
      if (_historyTo != null) {
        query['to'] = toIsoDateOnly(_historyTo!);
      }
      final res = await widget.api.dio.get<List<dynamic>>(
        '/orders/history',
        queryParameters: query.isEmpty ? null : query,
      );
      if (!mounted) return;
      setState(() {
        _historyOrders = (res.data ?? [])
            .map((e) => OrderDetailDto.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final str = AppStrings.of(context);
      TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyOrders = []);
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  /// Filtre historique : **modale** puis calendriers (comme la page Finances).
  Future<void> _pickHistoryRange() async {
    final str = AppStrings.of(context);
    final locale = Locale(str.isAr ? 'ar' : 'fr');
    final now = DateTime.now();

    DateTime start =
        _historyFrom ?? DateTime(now.year, now.month, now.day - 29);
    DateTime end = _historyTo ?? DateTime(now.year, now.month, now.day);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return AlertDialog(
            title: Text(str.posHistoryModalTitle),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    str.posHistoryModalHint,
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
      _historyFrom = a.isBefore(b) ? a : b;
      _historyTo = a.isBefore(b) ? b : a;
    });
    await _loadHistory();
  }

  void _clearHistoryRange() {
    setState(() {
      _historyFrom = null;
      _historyTo = null;
    });
    _loadHistory();
  }

  @override
  void initState() {
    super.initState();
    if (_serviceType == 'DELIVERY') {
      _serviceType = 'TAKEAWAY';
    }
    _refresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addToCart(String productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
    });
  }

  void _setQty(String productId, int q) {
    setState(() {
      if (q <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = q;
      }
    });
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
      final paidData = payRes.data;
      if (paidData != null) {
        current = OrderDetailDto.fromJson(paidData);
      }
    }

    if (discount > 0.009) {
      final remiseRes = await widget.api.dio.post<Map<String, dynamic>>(
        '/orders/${order.id}/payments',
        data: {
          'amount': discount,
          'method': 'CASH',
          'reference': 'REMISE',
        },
      );
      final remiseData = remiseRes.data;
      if (remiseData != null) {
        current = OrderDetailDto.fromJson(remiseData);
      }
    }

    return current;
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
          final validDiscount = discount >= 0 && discount <= subtotal + 0.001;
          final total = (subtotal - discount.clamp(0, subtotal))
              .clamp(0, double.infinity);

          return AlertDialog(
            title: Text('${str.posOrderTitle} #${order.orderNumber}'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(str.posTotal),
                      Text(
                        '${subtotal.toStringAsFixed(subtotal == subtotal.roundToDouble() ? 0 : 2)} FCFA',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountCtrl,
                    decoration: InputDecoration(
                      labelText: str.posDiscountOnTotal,
                      hintText: '0',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        str.posFinalTotal,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2)} FCFA',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  if (!validDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        str.posInvalidDiscount,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
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
                onPressed: validDiscount
                    ? () => Navigator.pop(ctx, true)
                    : null,
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
      if (mounted) {
        TopNotifier.warning(context, str.posOrderSaved);
      }
      return;
    }

    final parsedDiscount = double.tryParse(
          discountCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    final discount = parsedDiscount < 0
        ? 0.0
        : (parsedDiscount > subtotal ? subtotal : parsedDiscount);

    try {
      var settled = await _applyPaymentsWithDiscount(order, discount);
      final printOutcome = await _printReceipt(
        settled,
        discountFcfa: discount,
      );
      await _refresh(silent: true);
      if (!mounted) return;

      switch (printOutcome) {
        case ReceiptPrintOutcome.printed:
          TopNotifier.success(context, str.posOrderPaidPrinted);
        case ReceiptPrintOutcome.cancelled:
          TopNotifier.warning(context, str.posOrderSavedPrintCancelled);
        case ReceiptPrintOutcome.failed:
          TopNotifier.warning(context, str.posOrderSaved);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, '$e');
    }
  }

  Future<void> _submitOrder() async {
    final str = AppStrings.of(context);
    if (_cart.isEmpty) {
      TopNotifier.warning(context, str.posAddOneItem);
      return;
    }
    final items = [
      for (final e in _cart.entries)
        if (e.value > 0) {'productId': e.key, 'quantity': e.value},
    ];
    final body = <String, dynamic>{
      'serviceType': _serviceType,
      'items': items,
      if (_tableId != null && _serviceType == 'DINE_IN')
        'diningTableId': _tableId,
    };

    var orderCreated = false;
    OrderDetailDto? createdOrder;
    try {
      final createRes = await widget.api.dio.post<Map<String, dynamic>>(
        '/orders',
        data: body,
      );
      final createdData = createRes.data;
      if (createdData == null) {
        throw StateError('Réponse commande vide');
      }
      createdOrder = OrderDetailDto.fromJson(createdData);
      orderCreated = true;

      setState(() {
        _cart.clear();
      });
      if (!mounted) return;

      await _showFinalizeAndPrintDialog(createdOrder);
    } on DioException catch (e) {
      if (orderCreated && mounted) {
        setState(() => _cart.clear());
        await _refresh(silent: true);
      }
      if (!mounted) return;
      TopNotifier.error(
        context,
        userFacingDioMessage(e, str),
      );
    } catch (e) {
      if (orderCreated && mounted) {
        setState(() => _cart.clear());
        await _refresh(silent: true);
      }
      if (!mounted) return;
      TopNotifier.error(context, '$e');
    }
  }

  Future<void> _patchStatus(OrderDetailDto order, String status) async {
    try {
      await widget.api.dio.patch('/orders/${order.id}', data: {'status': status});
      await _refresh(silent: true);
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      final str = AppStrings.of(context);
      TopNotifier.error(context, userFacingDioMessage(e, str));
    }
  }

  Future<void> _submitPayment(OrderDetailDto order, double amount, String method) async {
    try {
      await widget.api.dio.post(
        '/orders/${order.id}/payments',
        data: {'amount': amount, 'method': method},
      );
      await _refresh(silent: true);
      if (mounted) {
        TopNotifier.success(context, AppStrings.of(context).posPaymentRecorded);
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final str = AppStrings.of(context);
      TopNotifier.error(context, userFacingDioMessage(e, str));
    }
  }

  Future<void> _showPaymentDialog(OrderDetailDto order) async {
    final str = AppStrings.of(context);
    final due = double.tryParse(order.totals.due.replaceAll(',', '.')) ?? 0;
    final amtCtrl = TextEditingController(text: due.toStringAsFixed(2));
    String method = _paymentValues.first;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text('${str.posPaymentTitle} #${order.orderNumber}'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${str.posDueLabel} : ${order.totals.due} FCFA'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amtCtrl,
                    decoration: InputDecoration(labelText: str.posAmountFcfa),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(method),
                    initialValue: method,
                    decoration: InputDecoration(labelText: str.posPaymentMethod),
                    items: [
                      for (final v in _paymentValues)
                        DropdownMenuItem(
                          value: v,
                          child: Text(str.posPayment(v)),
                        ),
                    ],
                    onChanged: (v) =>
                        setLocal(() => method = v ?? method),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(str.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final parsed = double.tryParse(
                    amtCtrl.text.trim().replaceAll(',', '.'),
                  );
                  if (parsed == null || parsed <= 0) return;
                  Navigator.pop(ctx);
                  _submitPayment(order, parsed, method);
                },
                child: Text(str.confirm),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showOrderDetail(OrderDetailDto order) async {
    var status = order.status;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          final str = AppStrings.of(context);
          final locked = order.status == 'PAID';
          return AlertDialog(
            title: Text('${str.posOrderTitle} #${order.orderNumber}'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${str.posService(order.serviceType)}'
                      '${order.diningTable != null ? ' · ${str.posTablePrefix} ${order.diningTable!.number}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if ((order.notes ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${str.posNotePrefix} : ${order.notes}'),
                      ),
                    if (order.customer != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${str.posCustomerPrefix} : ${order.customer!.name}'
                          '${order.customer!.phone.isNotEmpty ? ' · ${order.customer!.phone}' : ''}',
                        ),
                      ),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: str.posKitchenStatus,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: status,
                          isExpanded: true,
                          items: [
                            for (final v in _statusValues)
                              DropdownMenuItem(
                                value: v,
                                child: Text(str.posStatus(v)),
                              ),
                          ],
                          onChanged: locked
                              ? null
                              : (v) {
                                  if (v != null) setLocal(() => status = v);
                                },
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      str.posArticles,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final line in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${line.displayNameLocalized(str.isAr)} × ${line.quantity}',
                              ),
                            ),
                            Text(
                              '${(double.tryParse(line.unitPrice.replaceAll(',', '.')) ?? 0) * line.quantity} FCFA',
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(str.posTotal),
                        Text('${order.totals.subtotal} FCFA'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(str.posPaid),
                        Text('${order.totals.paid} FCFA'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          str.posRemain,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${order.totals.due} FCFA',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    if (order.payments.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        str.posPayments,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      for (final p in order.payments)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                _paymentIcon(p.method),
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${str.posPayment(p.method)}'
                                  '${p.createdAt.length >= 16 ? ' · ${p.createdAt.substring(0, 16).replaceFirst('T', ' ')}' : ''}',
                                ),
                              ),
                              Text('${p.amount} FCFA'),
                            ],
                          ),
                        ),
                    ],
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${str.posCreatedAtPrefix} ${order.createdAt.length >= 16 ? order.createdAt.substring(0, 16).replaceFirst('T', ' ') : order.createdAt}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (order.updatedAt.isNotEmpty &&
                        order.updatedAt != order.createdAt)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.update, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${str.posUpdatedAtPrefix} : ${order.updatedAt.length >= 16 ? order.updatedAt.substring(0, 16).replaceFirst('T', ' ') : order.updatedAt}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _printReceipt(order, dialogContext: ctx),
                icon: const Icon(Icons.print_outlined),
                label: Text(str.posPrint),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(str.posClose),
              ),
              if (!locked && order.status != 'CANCELLED')
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _showEditOrderCart(order);
                  },
                  child: Text(str.posEditCart),
                ),
              if (!locked && order.status != 'CANCELLED')
                FilledButton.tonal(
                  onPressed: () => _showPaymentDialog(order),
                  child: Text(str.posCollect),
                ),
              if (!locked)
                FilledButton(
                  onPressed: status == order.status
                      ? null
                      : () => _patchStatus(order, status),
                  child: Text(str.posUpdateStatus),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditOrderCart(OrderDetailDto order) async {
    final str = AppStrings.of(context);
    final cart = <String, int>{
      for (final line in order.items)
        if (line.product != null) line.product!.id: line.quantity,
    };

    await showDialog<void>(
      context: context,
      builder: (ctxEdit) => StatefulBuilder(
        builder: (context, setLocal) {
          Future<void> pickProduct() async {
            final id = await showModalBottomSheet<String>(
              context: context,
              builder: (sheetCtx) => SafeArea(
                child: ListView(
                  children: [
                    for (final p in _products)
                      ListTile(
                        title: Text(
                          p.displayName(preferArabic: str.isAr),
                        ),
                        subtitle: Text('${p.price} FCFA'),
                        onTap: () => Navigator.pop(sheetCtx, p.id),
                      ),
                  ],
                ),
              ),
            );
            if (id != null) {
              setLocal(() => cart[id] = (cart[id] ?? 0) + 1);
            }
          }

          Future<void> save() async {
            final items = [
              for (final e in cart.entries)
                if (e.value > 0)
                  <String, dynamic>{'productId': e.key, 'quantity': e.value},
            ];
            if (items.isEmpty) {
              TopNotifier.warning(context, str.posAddAtLeastOneLine);
              return;
            }
            try {
              await widget.api.dio.put(
                '/orders/${order.id}/items',
                data: {'items': items},
              );
              if (ctxEdit.mounted) Navigator.pop(ctxEdit);
              await _refresh(silent: true);
              if (context.mounted) {
                TopNotifier.success(context, str.posCartUpdatedDone);
              }
            } on DioException catch (e) {
              if (context.mounted) {
                TopNotifier.error(
                  context,
                  e.response?.data?.toString() ?? e.message ?? '',
                );
              }
            }
          }

          final lines = cart.entries.where((e) => e.value > 0).toList();

          return AlertDialog(
            title: Text('${str.posEditCartTitlePrefix} #${order.orderNumber}'),
            content: SizedBox(
              width: 420,
              height: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: pickProduct,
                      icon: const Icon(Icons.add),
                      label: Text(str.posAddProductLine),
                    ),
                  ),
                  Expanded(
                    child: lines.isEmpty
                        ? Center(child: Text(str.posCartEmptyDialog))
                        : ListView(
                            children: [
                              for (final e in lines)
                                ListTile(
                                  title: Text(
                                    _productById(e.key)?.displayName(
                                          preferArabic: str.isAr) ??
                                        str.posUnknownArticle,
                                  ),
                                  subtitle: Text(
                                    '${str.posQuantityPrefix} ${e.value}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: () => setLocal(() {
                                          final q = (cart[e.key] ?? 0) - 1;
                                          if (q <= 0) {
                                            cart.remove(e.key);
                                          } else {
                                            cart[e.key] = q;
                                          }
                                        }),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed: () => setLocal(() {
                                          cart[e.key] =
                                              (cart[e.key] ?? 0) + 1;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctxEdit),
                child: Text(str.cancel),
              ),
              FilledButton(onPressed: save, child: Text(str.save)),
            ],
          );
        },
      ),
    );
  }

  Widget _productImageTile(ProductDto p) {
    final outline = Theme.of(context).colorScheme.outline;
    final uri =
        resolveProductImageUri(p.imageUrl, widget.api.dio.options.baseUrl);
    if (uri == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.restaurant_outlined, color: outline),
      );
    }
    return Image.network(
      uri.toString(),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: outline, size: 28),
      ),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(ctx).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Iterable<ProductDto> get _filteredProducts {
    final cid = _categoryFilterId;
    if (cid == null) return _products;
    return _products.where((p) => p.category.id == cid);
  }

  Widget _buildProductGrid() {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = _filteredProducts.toList();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.84,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
            final p = list[i];
            final label = p.displayName(preferArabic: str.isAr);
            return Material(
              elevation: 1.5,
              shadowColor: cs.shadow.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: cs.surface,
              child: InkWell(
                onTap: p.isOutOfStock ? null : () => _addToCart(p.id),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 58,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _productImageTile(p),
                              PositionedDirectional(
                                start: 0,
                                end: 0,
                                bottom: 0,
                                height: 40,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withValues(alpha: 0.35),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 42,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                10, 8, 10, 10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer
                                              .withValues(alpha: 0.9),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${p.price} FCFA',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme
                                              .textTheme.labelLarge
                                              ?.copyWith(
                                            color: cs.onPrimaryContainer,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (p.tracksStock) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '${p.stockQuantity}',
                                        style: theme
                                            .textTheme.labelSmall
                                            ?.copyWith(
                                          color: p.isOutOfStock
                                              ? Colors.red.shade700
                                              : p.isLowStock
                                                  ? Colors
                                                      .orange.shade800
                                                  : cs.outline,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (p.isOutOfStock)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.38),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                str.posOutOfStock,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (p.isLowStock)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            str.posLowStock,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildCartPanel() {
    final str = AppStrings.of(context);
    final entries = _cart.entries.toList();
    final total = _cartTotalFcfa();
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_basket_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  str.posCartTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        str.posCartEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.outline,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final p = _productById(e.key);
                        final name = p?.displayName(preferArabic: str.isAr) ??
                            str.posUnknownArticle;
                        final unit = double.tryParse(
                                (p?.price ?? '0').replaceAll(',', '.')) ??
                            0;
                        final lineTotal = unit * e.value;
                        final imgUri = p != null
                            ? resolveProductImageUri(
                                p.imageUrl,
                                widget.api.dio.options.baseUrl,
                              )
                            : null;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: SizedBox(
                            width: 44,
                            height: 44,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imgUri == null
                                  ? ColoredBox(
                                      color: cs.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.restaurant_outlined,
                                        size: 22,
                                        color: cs.outline,
                                      ),
                                    )
                                  : Image.network(
                                      imgUri.toString(),
                                      fit: BoxFit.cover,
                                      width: 44,
                                      height: 44,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, _, _) => ColoredBox(
                                        color: cs.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 22,
                                          color: cs.outline,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text('$lineTotal FCFA'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _setQty(e.key, e.value - 1),
                              ),
                              Text('${e.value}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _setQty(e.key, e.value + 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 20),
            Text(
              '${str.posCartTotal} : ${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2)} FCFA',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_serviceType),
              initialValue: _serviceType,
              decoration: InputDecoration(labelText: str.posServiceType),
              items: [
                for (final v in _serviceValues)
                  DropdownMenuItem(
                    value: v,
                    child: Text(str.posService(v)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _serviceType = v);
              },
            ),
            if (_serviceType == 'DINE_IN') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey(_tableId),
                initialValue: _tableId,
                decoration: InputDecoration(labelText: str.posTable),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(str.noneShort),
                  ),
                  for (final t in _tables)
                    DropdownMenuItem<String?>(
                      value: t.id,
                      child: Text(
                        '${str.posTablePrefix} ${t.number} (${t.capacity} ${str.posTableCapacity})',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _tableId = v),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitOrder,
              icon: const Icon(Icons.restaurant_rounded),
              label: Text(str.posCreateOrder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewSale() {
    final str = AppStrings.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: str.posCategoryFilter),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _categoryFilterId,
                        isExpanded: true,
                        hint: Text(str.allCategories),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(str.allCategories),
                          ),
                          for (final c in _categories)
                            DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(categoryPickerLabel(c, _categories,
                                  preferArabic: str.isAr)),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categoryFilterId = v),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildProductGrid()),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget? _buildHistoryScopeHint() {
    if (_viewAllOrders) return null;
    final str = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(
        str.posHistoryScopedHint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }

  Widget _buildHistoryFilterBar() {
    final str = AppStrings.of(context);
    final hasFilter = _historyFrom != null || _historyTo != null;
    final label = hasFilter
        ? '${_historyFrom != null ? toIsoDateOnly(_historyFrom!) : '…'} '
            '→ ${_historyTo != null ? toIsoDateOnly(_historyTo!) : '…'}'
        : str.posFilterDates;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _pickHistoryRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(label),
          ),
          if (hasFilter)
            TextButton.icon(
              onPressed: _clearHistoryRange,
              icon: const Icon(Icons.close),
              label: Text(str.posClearFilter),
            ),
          TextButton.icon(
            onPressed: _historyLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh),
            label: Text(str.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final str = AppStrings.of(context);
    final scopeHint = _buildHistoryScopeHint();
    if (_historyLoading && _historyOrders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHistoryFilterBar(),
          if (scopeHint != null) scopeHint,
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_historyOrders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHistoryFilterBar(),
          if (scopeHint != null) scopeHint,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  str.posHistoryEmptyLong,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHistoryFilterBar(),
        if (scopeHint != null) scopeHint,
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _historyOrders.length,
            itemBuilder: (_, i) {
              final o = _historyOrders[i];
              final when = o.createdAt.length >= 16
                  ? o.createdAt.substring(0, 16).replaceFirst('T', ' ')
                  : o.createdAt;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    o.status == 'PAID'
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: o.status == 'PAID'
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.outline,
                  ),
                  title: Text('${str.posOrderTitle} #${o.orderNumber}'),
                  subtitle: Text(
                    '$when · ${str.posStatus(o.status)} · '
                    '${str.posTotal} ${o.totals.subtotal} · '
                    '${str.posService(o.serviceType)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showOrderDetail(o),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool get _viewAllOrders => userCanViewAllOrders(widget.user);

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(str.retry)),
          ],
        ),
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Icon(Icons.point_of_sale_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    str.posPageTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: str.refresh,
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (_error != null &&
              (_categories.isNotEmpty || _products.isNotEmpty))
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.wifi_off_outlined,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            str.posNetworkBannerHint,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _refresh(silent: true),
                      child: Text(str.retry),
                    ),
                    IconButton(
                      tooltip: str.cancel,
                      onPressed: () => setState(() => _error = null),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(str.posSegmentNew)),
                ButtonSegment(
                  value: 1,
                  label: Text(str.posSegmentHistoryScoped(_viewAllOrders)),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) async {
                final idx = s.first;
                setState(() => _segment = idx);
                await _refresh(silent: true);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _segment == 0 ? _buildNewSale() : _buildHistory(),
          ),
        ],
      ),
    );
  }
}
