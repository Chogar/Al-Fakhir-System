class SalesBreakdownDto {
  const SalesBreakdownDto({
    this.dineIn = '0',
    this.takeaway = '0',
    this.delivery = '0',
  });

  final String dineIn;
  final String takeaway;
  final String delivery;

  factory SalesBreakdownDto.fromJson(Map<String, dynamic> j) {
    final b = j['breakdown'];
    if (b is Map<String, dynamic>) {
      return SalesBreakdownDto(
        dineIn: b['DINE_IN']?.toString() ?? '0',
        takeaway: b['TAKEAWAY']?.toString() ?? '0',
        delivery: b['DELIVERY']?.toString() ?? '0',
      );
    }
    return const SalesBreakdownDto();
  }
}
