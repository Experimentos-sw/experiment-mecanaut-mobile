import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';

class MetricDefinitionItem {
  MetricDefinitionItem({
    required this.id,
    required this.name,
    required this.unit,
  });

  final int id;
  final String name;
  final String unit;

  factory MetricDefinitionItem.fromMap(Map<String, dynamic> map) {
    return MetricDefinitionItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
    );
  }
}

class MetricDefinitionsService {
  MetricDefinitionsService(this._dio);

  final Dio _dio;

  Future<List<MetricDefinitionItem>> getDefinitions() async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.metricDefinitions);
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list.map((e) => MetricDefinitionItem.fromMap(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudieron cargar metricas.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}

