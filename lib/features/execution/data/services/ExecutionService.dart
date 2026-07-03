import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/purchase_order_item.dart'; // Just using this for reference? No, parts
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/work_orders/data/models/work_order_item.dart';
import 'package:mecanaut_mobile/features/execution/data/models/save_executed_work_order_request.dart';
import 'package:http_parser/http_parser.dart';

// Since inventory part is not modeled properly yet if not in inventory folder, let's define a simple model here or use dynamic
class InventoryPartDto {
  InventoryPartDto({
    required this.id,
    required this.name,
    required this.code,
    required this.currentStock,
  });

  final int id;
  final String name;
  final String code;
  final int currentStock;

  factory InventoryPartDto.fromMap(Map<String, dynamic> map) {
    return InventoryPartDto(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      currentStock: (map['currentStock'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExecutionService {
  ExecutionService(this._dio);

  final Dio _dio;

  Future<List<PlantItem>> getPlants() async {
    try {
      final response = await _dio.get(ApiPaths.plants);
      final List<dynamic> data = response.data;
      return data.map((json) => PlantItem.fromMap(json)).toList();
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }

  Future<List<ProductionLineItem>> getProductionLines(int plantId) async {
    try {
      final response = await _dio.get('${ApiPaths.productionLines}/plant/$plantId');
      final List<dynamic> data = response.data;
      return data.map((json) => ProductionLineItem.fromMap(json)).toList();
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }

  Future<List<InventoryPartDto>> getInventoryParts(int plantId) async {
    try {
      final response = await _dio.get('${ApiPaths.inventoryParts}?plantId=$plantId');
      final List<dynamic> data = response.data;
      return data.map((json) => InventoryPartDto.fromMap(json)).toList();
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }

  Future<List<WorkOrderItem>> getWorkOrdersToExecute(int productionLineId) async {
    try {
      final response = await _dio.get('${ApiPaths.workOrders}/by-production-line-to-execute/$productionLineId');
      final List<dynamic> data = response.data;
      return data.map((json) => WorkOrderItem.fromMap(json)).toList();
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }
  
  Future<List<MachineItem>> getMachineriesByWorkOrder(WorkOrderItem order) async {
    try {
      if (order.machineIds.isEmpty) return [];
      
      List<MachineItem> machines = [];
      for (final machineId in order.machineIds) {
        try {
          final response = await _dio.get('${ApiPaths.machines}/$machineId');
          machines.add(MachineItem.fromMap(response.data));
        } catch (e) {
          // Ignore individual machine errors
        }
      }
      return machines;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveExecutedWorkOrder(SaveExecutedWorkOrderRequest request) async {
    try {
      await _dio.post(ApiPaths.executedWorkOrders, data: request.toMap());
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }

  Future<List<ExecutedWorkOrderDto>> getExecutedWorkOrdersByProductionLine(int productionLineId) async {
    try {
      final response = await _dio.get('${ApiPaths.executedWorkOrders}/production-line/$productionLineId');
      final List<dynamic> data = response.data;
      return data.map((json) => ExecutedWorkOrderDto.fromMap(json)).toList();
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }

  Future<ExecutedWorkOrderDto> getExecutedWorkOrder(int id) async {
    try {
      final response = await _dio.get('${ApiPaths.executedWorkOrders}/$id');
      return ExecutedWorkOrderDto.fromMap(response.data);
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }

  Future<String> uploadImage(String filePath, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        '/api/image-storage/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      if (response.data is String) {
        return response.data;
      } else if (response.data != null && response.data['url'] != null) {
        return response.data['url'];
      }
      throw Exception('Formato de respuesta no válido del servidor');
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Error de red', details: e);
    }
  }
}
