class CreateWorkOrderRequest {
  CreateWorkOrderRequest({
    required this.code,
    required this.date,
    required this.productionLineId,
    required this.type,
    required this.machineIds,
    required this.tasks,
    required this.technicianIds,
  });

  final String code;
  final DateTime date;
  final int productionLineId;
  final String type;
  final List<int> machineIds;
  final List<String> tasks;
  final List<int?> technicianIds;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'date': date.toIso8601String(),
      'productionLineId': productionLineId,
      'type': type,
      'machineIds': machineIds,
      'tasks': tasks,
      'technicianIds': technicianIds,
    };
  }
}
