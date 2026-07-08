class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.slug,
    required this.labelFr,
    this.labelAr,
    this.sortOrder = 0,
    this.productCount = 0,
  });

  final String id;
  final String slug;
  final String labelFr;
  final String? labelAr;
  final int sortOrder;
  final int productCount;

  factory CategoryDto.fromJson(Map<String, dynamic> j) {
    return CategoryDto(
      id: j['id']?.toString() ?? '',
      slug: j['slug']?.toString() ?? '',
      labelFr: j['labelFr']?.toString() ?? '',
      labelAr: j['labelAr'] as String?,
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      productCount: (j['productCount'] as num?)?.toInt() ?? 0,
    );
  }

  String label({required bool preferArabic}) {
    if (preferArabic && (labelAr?.trim().isNotEmpty ?? false)) {
      return labelAr!.trim();
    }
    return labelFr;
  }
}

List<CategoryDto> dedupeCategoriesForMenu(List<CategoryDto> items) {
  final seen = <String>{};
  final out = <CategoryDto>[];
  for (final c in items) {
    if (seen.add(c.id)) out.add(c);
  }
  out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return out;
}

String categoryPickerLabel(
  CategoryDto c,
  List<CategoryDto> all, {
  required bool preferArabic,
  bool disambiguateWithSlug = false,
}) {
  final text = c.label(preferArabic: preferArabic);
  final dup = disambiguateWithSlug ||
      all.where((x) => x.label(preferArabic: preferArabic) == text).length > 1;
  return dup ? '$text (${c.slug})' : text;
}

/// Slug technique (MAJUSCULES, sans accents) à partir d'un libellé FR.
String categorySlugFromLabel(String label) {
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
  };
  var s = label.toLowerCase().trim();
  s = s.split('').map((c) => accents[c] ?? c).join();
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  s = s.toUpperCase();
  if (s.isEmpty) return 'CAT';
  return s;
}
