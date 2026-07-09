import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/telemetry_resource.dart';

class ExperimentTelemetryService {
  ExperimentTelemetryService(this._dio);

  final Dio _dio;

  Future<void> recordMetric(TelemetryResource resource) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/experiment-telemetry',
        data: resource.toMap(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudo enviar la telemetría.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}
