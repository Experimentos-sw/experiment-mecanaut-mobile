import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/purchase_order_item.dart';

class PurchaseOrdersService {
  PurchaseOrdersService(this._dio);

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

  Future<List<PurchaseOrderItem>> getPurchaseOrders(int plantId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.purchaseOrders,
        queryParameters: <String, dynamic>{'plantId': plantId},
      );
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => PurchaseOrderItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e, 'No se pudieron cargar ordenes de compra.');
    }
  }

  Future<PurchaseOrderItem> getById(int id) async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.purchaseOrders}/$id');
      return PurchaseOrderItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo cargar la orden.');
    }
  }

  Future<PurchaseOrderItem> create(PurchaseOrderCreateRequest request) async {
    try {
      final response = await _dio.post<dynamic>(ApiPaths.purchaseOrders, data: request.toMap());
      return PurchaseOrderItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo crear la orden de compra.');
    }
  }

  Future<PurchaseOrderItem> complete(int id) async {
    try {
      final response = await _dio.patch<dynamic>('${ApiPaths.purchaseOrders}/$id/complete');
      return PurchaseOrderItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo completar la orden de compra.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<dynamic>('${ApiPaths.purchaseOrders}/$id');
    } on DioException catch (e) {
      throw _map(e, 'No se pudo eliminar la orden de compra.');
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
