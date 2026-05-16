import 'category_model.dart';

class ProductDto {
  const ProductDto({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.price,
    required this.isAvailable,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.productNumber = 0,
    this.stockQuantity,
    this.stockAlertThreshold = 0,
  });

  final String id;

  /// Numéro affiché en caisse et dans le menu (attribué automatiquement).
  final int productNumber;

  final String name;

  /// Libellé arabe optionnel (affiche en interface AR si renseigné).
  final String nameAr;

  final String price;
  final bool isAvailable;
  final String description;
  final String imageUrl;
  final CategoryDto category;

  /// Stock courant. `null` = produit non suivi (pas de gestion d'inventaire).
  final int? stockQuantity;

  /// Seuil sous lequel le produit est considéré « stock bas ».
  final int stockAlertThreshold;

  /// True si le suivi de stock est actif pour ce produit.
  bool get tracksStock => stockQuantity != null;

  /// True si stock courant <= 0 et que le suivi est actif.
  bool get isOutOfStock => tracksStock && (stockQuantity ?? 0) <= 0;

  /// True si stock courant <= seuil d'alerte (mais pas encore en rupture).
  bool get isLowStock =>
      tracksStock &&
      !isOutOfStock &&
      (stockQuantity ?? 0) <= stockAlertThreshold;

  /// Libellé affiché selon la langue de l’interface.
  String displayName({required bool preferArabic}) {
    if (preferArabic && nameAr.trim().isNotEmpty) {
      return nameAr.trim();
    }
    return name.trim();
  }

  factory ProductDto.fromJson(Map<String, dynamic> j) {
    final cat = j['category'] as Map<String, dynamic>?;
    if (cat == null) {
      throw const FormatException('Produit sans catégorie');
    }
    final rawPrice = j['price'];
    final priceStr =
        rawPrice is num ? rawPrice.toString() : (rawPrice as String? ?? '0');
    final rawStock = j['stockQuantity'];
    final rawAlert = j['stockAlertThreshold'];
    final rawNum = j['productNumber'] ?? j['product_number'];
    return ProductDto(
      id: j['id'] as String,
      productNumber: rawNum is num ? rawNum.toInt() : 0,
      name: j['name'] as String,
      nameAr: (j['nameAr'] as String?) ?? '',
      price: priceStr,
      isAvailable: j['isAvailable'] as bool,
      description: (j['description'] as String?) ?? '',
      imageUrl: (j['imageUrl'] as String?) ?? '',
      category: CategoryDto.fromJson(cat),
      stockQuantity:
          rawStock is num ? rawStock.toInt() : null,
      stockAlertThreshold:
          rawAlert is num ? rawAlert.toInt() : 0,
    );
  }
}
