enum MaintenancePlanType { staticPlan, dynamicPlan }

class MaintenancePlanItem {
  MaintenancePlanItem({
    required this.id,
    required this.name,
    required this.type,
    required this.productionLineId,
    required this.machineIds,
    required this.taskDescriptions,
    this.metricId,
    this.amount,
    this.status = 'En curso',
    this.nextDateLabel,
  });

  final String id;
  final String name;
  final MaintenancePlanType type;
  final int? productionLineId;
  final List<int> machineIds;
  final List<String> taskDescriptions;
  final int? metricId;
  final double? amount;
  final String status;
  final String? nextDateLabel;
}

