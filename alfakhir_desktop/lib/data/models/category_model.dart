class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.slug,
    required this.labelFr,
    this.labelAr,
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final String labelFr;
  final String? labelAr;
  final int sortOrder;

  factory CategoryDto.fromJson(Map<String, dynamic> j) {
    return CategoryDto(
      id: j['id']?.toString() ?? '',
      slug: j['slug']?.toString() ?? '',
      labelFr: j['labelFr']?.toString() ?? '',
      labelAr: j['labelAr'] as String?,
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  String label({required bool preferArabic}) {
    if (preferArabic && (labelAr?.trim().isNotEmpty ?? false)) {
      return labelAr!.trim();
    }
    return labelFr;
  }
}
