import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/create_experiment_survey_request.dart';

class ExperimentSurveysService {
  ExperimentSurveysService(this._dio);

  final Dio _dio;

  Future<void> create(CreateExperimentSurveyRequest request) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/experiment-surveys',
        data: request.toMap(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudo enviar la encuesta.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}
