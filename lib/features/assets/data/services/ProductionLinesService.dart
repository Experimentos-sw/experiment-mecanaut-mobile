import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';

class ProductionLineItem {
  ProductionLineItem({
    required this.id,
    required this.name,
    required this.code,
    required this.capacityUnitsPerHour,
    required this.status,
    required this.plantId,
  });

  final int id;
  final String name;
  final String code;
  final double capacityUnitsPerHour;
  final String status;
  final int plantId;

  String get display => code.isNotEmpty ? code : name;
  bool get isActive => status.toLowerCase() == 'active';

  factory ProductionLineItem.fromMap(Map<String, dynamic> map) {
    return ProductionLineItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      capacityUnitsPerHour: (map['capacityUnitsPerHour'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? '',
      plantId: (map['plantId'] as num?)?.toInt() ?? 0,
    );
  }
}

class CreateProductionLineRequest {
  CreateProductionLineRequest({
    required this.name,
    required this.code,
    required this.capacityUnitsPerHour,
    required this.plantId,
  });

  final String name;
  final String code;
  final double capacityUnitsPerHour;
  final int plantId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'capacityUnitsPerHour': capacityUnitsPerHour,
      'plantId': plantId,
    };
  }
}

class ProductionLinesService {
  ProductionLinesService(this._dio);

  final Dio _dio;

  Future<List<ProductionLineItem>> getProductionLines({int? plantId}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.productionLines,
        queryParameters: plantId == null ? null : <String, dynamic>{'plantId': plantId},
      );
      final data = response.data as List<dynamic>? ?? <dynamic>[];
      return data
          .map(
            (dynamic e) =>
                ProductionLineItem.fromMap(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudo cargar lineas de produccion.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<ProductionLineItem> create(CreateProductionLineRequest request) async {
    try {
      final response = await _dio.post<dynamic>(ApiPaths.productionLines, data: request.toMap());
      return ProductionLineItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudo crear la linea de produccion.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<void> start(int id) async {
    try {
      await _dio.put<dynamic>('${ApiPaths.productionLines}/$id/start');
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudo iniciar la linea.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<void> stop(int id, {required String reason}) async {
    try {
      await _dio.put<dynamic>(
        '${ApiPaths.productionLines}/$id/stop',
        data: <String, dynamic>{'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudo detener la linea.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}
