class DiningTableDto {
  const DiningTableDto({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    required this.tableType,
  });

  final String id;
  final int number;
  final int capacity;
  final String status;
  final String tableType;

  factory DiningTableDto.fromJson(Map<String, dynamic> j) {
    return DiningTableDto(
      id: j['id'] as String,
      number: (j['number'] as num).toInt(),
      capacity: (j['capacity'] as num).toInt(),
      status: j['status'] as String,
      tableType: j['tableType'] as String,
    );
  }

  Map<String, dynamic> toCreateBody({String? status}) => {
        'number': number,
        'capacity': capacity,
        'tableType': tableType,
        ...? (status != null ? {'status': status} : null),
      };

  Map<String, dynamic> toPatchBody() => {
        'number': number,
        'capacity': capacity,
        'tableType': tableType,
        'status': status,
      };
}
