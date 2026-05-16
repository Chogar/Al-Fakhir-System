import '../../data/models/product_model.dart';

/// Libellé court pour affichage (ex. « 12 », « 128 »).
String formatProductNumber(int n) {
  if (n <= 0) return '—';
  return n.toString();
}

int compareProductsAlphabetically(
  ProductDto a,
  ProductDto b, {
  required bool preferArabic,
}) {
  final byName = a
      .displayName(preferArabic: preferArabic)
      .toLowerCase()
      .compareTo(b.displayName(preferArabic: preferArabic).toLowerCase());
  if (byName != 0) return byName;
  return a.productNumber.compareTo(b.productNumber);
}

void sortProductsAlphabetically(
  List<ProductDto> products, {
  required bool preferArabic,
}) {
  products.sort(
    (a, b) => compareProductsAlphabetically(a, b, preferArabic: preferArabic),
  );
}
