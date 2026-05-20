import 'package:alfakhir_desktop/core/pos/order_payload_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects empty cart', () {
    final issue = validateOrderPayload(
      cart: const {},
      serviceType: 'TAKEAWAY',
      tableId: null,
    );
    expect(issue, isNotNull);
  });

  test('rejects dine-in without table', () {
    final issue = validateOrderPayload(
      cart: const {'p1': 1},
      serviceType: 'DINE_IN',
      tableId: null,
    );
    expect(issue?.message, contains('table'));
  });

  test('accepts dine-in with table', () {
    final issue = validateOrderPayload(
      cart: const {'p1': 2},
      serviceType: 'DINE_IN',
      tableId: 'table-1',
    );
    expect(issue, isNull);
  });

  test('builds positive quantity items only', () {
    final items = buildOrderItems(const {'a': 2, 'b': 0, 'c': -1});
    expect(items, hasLength(1));
    expect(items.first['productId'], 'a');
    expect(items.first['quantity'], 2);
  });
}
