import 'package:mecanaut_mobile/features/maintenance_plans/data/models/dynamic_maintenance_plan_dto.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/maintenance_plan_item.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/presentation/controllers/StaticMaintenancePlanDraftController.dart';

class MaintenancePlanMapper {
  static MaintenancePlanItem fromDynamic(
    DynamicMaintenancePlanDto dto, {
    required int productionLineId,
  }) {
    return MaintenancePlanItem(
      id: dto.id,
      name: dto.name,
      type: MaintenancePlanType.dynamicPlan,
      productionLineId: productionLineId,
      machineIds: dto.machineIds,
      taskDescriptions: dto.taskDescriptions,
      metricId: int.tryParse(dto.metricId),
      amount: double.tryParse(dto.amount),
      status: 'En curso',
    );
  }

  static MaintenancePlanItem fromStaticDraft(StaticMaintenancePlanDraftController draft) {
    return MaintenancePlanItem(
      id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
      name: draft.name,
      type: MaintenancePlanType.staticPlan,
      productionLineId: draft.productionLineId,
      machineIds: draft.selectedMachineIds,
      taskDescriptions: draft.days.expand((d) => d.tasks.map((t) => t.description)).toList(),
      status: 'Pendiente',
      nextDateLabel: draft.startDate == null ? null : '${draft.startDate!.day}/${draft.startDate!.month}/${draft.startDate!.year}',
    );
  }
}

