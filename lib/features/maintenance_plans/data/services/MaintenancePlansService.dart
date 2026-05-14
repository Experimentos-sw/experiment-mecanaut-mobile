import 'package:mecanaut_mobile/features/maintenance_plans/data/mappers/MaintenancePlanMapper.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/maintenance_plan_item.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/services/DynamicMaintenancePlansService.dart';

class MaintenancePlansService {
  MaintenancePlansService(this._dynamicService);

  final DynamicMaintenancePlansService _dynamicService;

  Future<List<MaintenancePlanItem>> getPlansByLine(int productionLineId) async {
    final dynamicPlans = await _dynamicService.getByPlantLine(productionLineId.toString());
    return dynamicPlans
        .map((dto) => MaintenancePlanMapper.fromDynamic(dto, productionLineId: productionLineId))
        .toList();
  }
}

