import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/inventory_part_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

class InventoryPartsService {
  InventoryPartsService(this._dio);

  final Dio _dio;

  Future<List<PlantItem>> getPlants() async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.plants);
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list.map((dynamic e) => PlantItem.fromMap(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _map(e, 'No se pudieron cargar plantas.');
    }
  }

  Future<List<InventoryPartItem>> getParts(int plantId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.inventoryParts,
        queryParameters: <String, dynamic>{'plantId': plantId},
      );
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => InventoryPartItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e, 'No se pudieron cargar repuestos.');
    }
  }

  Future<InventoryPartItem> getById(int id) async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.inventoryParts}/$id');
      return InventoryPartItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo cargar el repuesto.');
    }
  }

  Future<InventoryPartItem> create(InventoryPartCreateRequest request) async {
    try {
      final response = await _dio.post<dynamic>(ApiPaths.inventoryParts, data: request.toMap());
      return InventoryPartItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo crear el repuesto.');
    }
  }

  Future<InventoryPartItem> update(int id, InventoryPartUpdateRequest request) async {
    try {
      final response = await _dio.put<dynamic>('${ApiPaths.inventoryParts}/$id', data: request.toMap());
      return InventoryPartItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo actualizar el repuesto.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<dynamic>('${ApiPaths.inventoryParts}/$id');
    } on DioException catch (e) {
      throw _map(e, 'No se pudo eliminar el repuesto.');
    }
  }

  Future<void> decreaseStock(int id, int quantity) async {
    try {
      await _dio.put<dynamic>('${ApiPaths.inventoryParts}/$id/decrease', data: quantity);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo disminuir stock.');
    }
  }

  ApiException _map(DioException e, String fallback) {
    return ApiException(
      message: e.response?.data?['message']?.toString() ??
          e.response?.data?['error']?.toString() ??
          e.response?.data?.toString() ??
          fallback,
      statusCode: e.response?.statusCode,
      details: e.response?.data,
    );
  }
}
