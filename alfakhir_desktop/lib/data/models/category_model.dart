class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.slug,
    required this.labelFr,
    required this.labelAr,
    required this.sortOrder,
    this.productCount = 0,
  });

  final String id;
  final String slug;
  final String labelFr;
  final String labelAr;
  final int sortOrder;

  /// Renseigné quand la liste vient de `/categories` (API enrichie).
  final int productCount;

  factory CategoryDto.fromJson(Map<String, dynamic> j) {
    return CategoryDto(
      id: j['id'] as String,
      slug: j['slug'] as String,
      labelFr: j['labelFr'] as String,
      labelAr: (j['labelAr'] as String?) ?? '',
      sortOrder: (j['sortOrder'] as num).toInt(),
      productCount: (j['productCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Supprime les entrées avec le même `id` si la liste API les répète (réordonné par `sortOrder`, libellé).
List<CategoryDto> dedupeCategoriesForMenu(List<CategoryDto> raw) {
  if (raw.isEmpty) return raw;
  final byId = <String, CategoryDto>{};
  for (final c in raw) {
    byId[c.id] = c;
  }
  final out = byId.values.toList();
  out.sort((a, b) {
    final o = a.sortOrder.compareTo(b.sortOrder);
    if (o != 0) return o;
    return a.labelFr.compareTo(b.labelFr);
  });
  return out;
}

/// Libellé dans les listes : par défaut uniquement le libellé (FR ou AR).
/// Si [disambiguateWithSlug] est vrai et plusieurs catégories partagent le
/// même libellé affiché, on ajoute le slug (réservé aux écrans admin).
///
/// [preferArabic] : utilise [CategoryDto.labelAr] lorsqu’il est renseigné.
String categoryPickerLabel(
  CategoryDto c,
  List<CategoryDto> orderedList, {
  bool preferArabic = false,
  bool disambiguateWithSlug = false,
}) {
  String display(CategoryDto x) {
    if (preferArabic && x.labelAr.trim().isNotEmpty) {
      return x.labelAr.trim();
    }
    return x.labelFr.trim();
  }

  final primary = display(c);
  if (!disambiguateWithSlug) {
    return primary;
  }
  final same = orderedList.where((x) => display(x) == primary).length;
  if (same > 1) {
    return '$primary (${c.slug})';
  }
  return primary;
}
