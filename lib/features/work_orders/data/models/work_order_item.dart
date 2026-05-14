class WorkOrderItem {
  WorkOrderItem({
    required this.id,
    required this.code,
    required this.status,
    required this.type,
    required this.date,
    required this.productionLineId,
    required this.machineIds,
    required this.technicianIds,
    required this.tasks,
  });

  final int id;
  final String code;
  final String status;
  final String type;
  final DateTime? date;
  final int productionLineId;
  final List<int> machineIds;
  final List<int> technicianIds;
  final List<String> tasks;

  factory WorkOrderItem.fromMap(Map<String, dynamic> map) {
    return WorkOrderItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      code: map['code']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString())
          : null,
      productionLineId: (map['productionLineId'] as num?)?.toInt() ?? 0,
      machineIds: (map['machineIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => (e as num).toInt())
          .toList(),
      technicianIds:
          (map['technicianIds'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<num>()
              .map((num e) => e.toInt())
              .toList(),
      tasks: (map['tasks'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
    );
  }
}
