class ExpenseDto {
  const ExpenseDto({
    required this.id,
    required this.label,
    required this.amount,
    required this.spentOn,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final String amount;
  final String spentOn;
  final String? category;
  final String createdAt;
  final String updatedAt;

  factory ExpenseDto.fromJson(Map<String, dynamic> j) {
    final rawAmt = j['amount'];
    final amt =
        rawAmt is num ? rawAmt.toString() : (rawAmt as String? ?? '0');
    final rawSpent = j['spentOn'];
    return ExpenseDto(
      id: j['id'] as String,
      label: j['label'] as String,
      amount: amt,
      spentOn: rawSpent?.toString() ?? '',
      category: j['category'] as String?,
      createdAt: j['createdAt']?.toString() ?? '',
      updatedAt: j['updatedAt']?.toString() ?? '',
    );
  }
}
