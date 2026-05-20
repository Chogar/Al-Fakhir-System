class ProductDto {
  const ProductDto({
    required this.id,
    required this.name,
    this.nameAr,
    required this.price,
    this.imageUrl,
    this.description,
    this.isAvailable = true,
    this.productNumber = 0,
    this.categoryId,
    this.categorySlug,
  });

  final String id;
  final String name;
  final String? nameAr;
  final String price;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;
  final int productNumber;
  final String? categoryId;
  final String? categorySlug;

  factory ProductDto.fromJson(Map<String, dynamic> j) {
    final cat = j['category'];
    return ProductDto(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      nameAr: j['nameAr'] as String?,
      price: j['price']?.toString() ?? '0',
      imageUrl: j['imageUrl'] as String?,
      description: j['description'] as String?,
      isAvailable: j['isAvailable'] as bool? ?? true,
      productNumber: (j['productNumber'] as num?)?.toInt() ?? 0,
      categoryId: cat is Map ? cat['id']?.toString() : null,
      categorySlug: cat is Map ? cat['slug'] as String? : null,
    );
  }

  String displayName({required bool preferArabic}) {
    if (preferArabic && (nameAr?.trim().isNotEmpty ?? false)) {
      return nameAr!.trim();
    }
    return name;
  }
}
