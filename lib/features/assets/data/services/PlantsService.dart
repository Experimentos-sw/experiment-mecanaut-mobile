import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

class CreatePlantRequest {
  CreatePlantRequest({
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    required this.phone,
    required this.email,
  });

  final String name;
  final String address;
  final String city;
  final String country;
  final String phone;
  final String email;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'city': city,
      'country': country,
      'phone': phone,
      'email': email,
    };
  }
}

class PlantsService {
  PlantsService(this._dio);

  final Dio _dio;

  Future<List<PlantItem>> getPlants() async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.plants);
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => PlantItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e, 'No se pudieron cargar plantas.');
    }
  }

  Future<PlantItem> createPlant(CreatePlantRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiPaths.plants,
        data: request.toMap(),
      );
      return PlantItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo crear la planta.');
    }
  }

  Future<void> activatePlant(int plantId) async {
    try {
      await _dio.put<dynamic>('${ApiPaths.plants}/$plantId/activate');
    } on DioException catch (e) {
      throw _map(e, 'No se pudo activar la planta.');
    }
  }

  Future<void> deactivatePlant(int plantId) async {
    try {
      await _dio.put<dynamic>('${ApiPaths.plants}/$plantId/deactivate');
    } on DioException catch (e) {
      throw _map(e, 'No se pudo desactivar la planta.');
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
