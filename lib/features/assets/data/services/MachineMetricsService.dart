import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';

class MachineMetricItem {
  MachineMetricItem({
    required this.metricId,
    required this.metricName,
    required this.unit,
    required this.value,
    required this.measuredAt,
  });

  final int metricId;
  final String metricName;
  final String unit;
  final double? value;
  final DateTime? measuredAt;

  factory MachineMetricItem.fromMap(Map<String, dynamic> map) {
    return MachineMetricItem(
      metricId: (map['metricId'] as num?)?.toInt() ?? 0,
      metricName: map['metricName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      value: (map['value'] as num?)?.toDouble(),
      measuredAt: map['measuredAt'] == null
          ? null
          : DateTime.tryParse(map['measuredAt'].toString()),
    );
  }
}

class UpdateMachineMetricRequest {
  UpdateMachineMetricRequest({
    required this.metricId,
    required this.value,
    required this.measuredAt,
  });

  final int metricId;
  final double value;
  final DateTime measuredAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'metricId': metricId,
      'value': value,
      'measuredAt': measuredAt.toUtc().toIso8601String(),
    };
  }
}

class MachineMetricsService {
  MachineMetricsService(this._dio);

  final Dio _dio;

  Future<List<MachineMetricItem>> getMachineMetrics(int machineId) async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/machines/$machineId/metrics');
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => MachineMetricItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?.toString() ??
            'No se pudieron cargar metricas de la maquinaria.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<void> updateMachineMetric(
    int machineId,
    UpdateMachineMetricRequest request,
  ) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/machines/$machineId/metrics',
        data: request.toMap(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?.toString() ??
            'No se pudo actualizar la metrica.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}
