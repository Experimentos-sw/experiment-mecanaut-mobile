class DynamicMaintenancePlanDto {
  DynamicMaintenancePlanDto({
    required this.id,
    required this.name,
    required this.metricId,
    required this.amount,
    required this.machineIds,
    required this.taskDescriptions,
  });

  final String id;
  final String name;
  final String metricId;
  final String amount;
  final List<int> machineIds;
  final List<String> taskDescriptions;

  factory DynamicMaintenancePlanDto.fromMap(Map<String, dynamic> map) {
    return DynamicMaintenancePlanDto(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      metricId: map['metricId']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '0',
      machineIds: (map['machineIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toList(),
      taskDescriptions: (map['taskDescriptions'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class SaveDynamicMaintenancePlanRequest {
  SaveDynamicMaintenancePlanRequest({
    required this.name,
    required this.metricId,
    required this.amount,
    required this.productionLineId,
    required this.plantLineId,
    required this.machines,
    required this.tasks,
  });

  final String name;
  final String metricId;
  final String amount;
  final String productionLineId;
  final String plantLineId;
  final List<int> machines;
  final List<String> tasks;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'metricId': metricId,
      'amount': amount,
      'productionLineId': productionLineId,
      'plantLineId': plantLineId,
      'machines': machines,
      'tasks': tasks,
    };
  }
}

