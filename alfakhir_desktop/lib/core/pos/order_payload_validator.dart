class OrderPayloadIssue {
  const OrderPayloadIssue(this.message);

  final String message;
}

OrderPayloadIssue? validateOrderPayload({
  required Map<String, int> cart,
  required String serviceType,
}) {
  final hasItems = cart.entries.any((entry) => entry.value > 0);
  if (!hasItems) {
    return const OrderPayloadIssue('Ajoutez au moins un produit');
  }
  return null;
}

List<Map<String, dynamic>> buildOrderItems(Map<String, int> cart) {
  return [
    for (final entry in cart.entries)
      if (entry.value > 0) {'productId': entry.key, 'quantity': entry.value},
  ];
}
