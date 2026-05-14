import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';

class MachineItem {
  MachineItem({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.type,
    required this.powerConsumption,
    required this.status,
    required this.productionLineId,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
  });

  final int id;
  final String serialNumber;
  final String name;
  final String manufacturer;
  final String model;
  final String type;
  final double powerConsumption;
  final String status;
  final int? productionLineId;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;

  String get display => serialNumber.isNotEmpty ? serialNumber : name;
  bool get isActive => status.toLowerCase() == 'active';
  bool get isMaintenance => status.toLowerCase() == 'maintenance';

  factory MachineItem.fromMap(Map<String, dynamic> map) {
    return MachineItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      serialNumber: map['serialNumber']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      manufacturer: map['manufacturer']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      powerConsumption: (map['powerConsumption'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? '',
      productionLineId: (map['productionLineId'] as num?)?.toInt(),
      lastMaintenanceDate: map['lastMaintenanceDate'] == null
          ? null
          : DateTime.tryParse(map['lastMaintenanceDate'].toString()),
      nextMaintenanceDate: map['nextMaintenanceDate'] == null
          ? null
          : DateTime.tryParse(map['nextMaintenanceDate'].toString()),
    );
  }
}

class MachineMetricCreateItem {
  MachineMetricCreateItem({
    required this.metricId,
    required this.value,
    this.measuredAt,
  });

  final int metricId;
  final double value;
  final DateTime? measuredAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'metricId': metricId,
      'value': value,
      'measuredAt': measuredAt?.toUtc().toIso8601String(),
    };
  }
}

class RegisterMachineRequest {
  RegisterMachineRequest({
    required this.serialNumber,
    required this.name,
    required this.manufacturer,
    required this.plantId,
    required this.model,
    required this.type,
    required this.powerConsumption,
    required this.metrics,
  });

  final String serialNumber;
  final String name;
  final String manufacturer;
  final int plantId;
  final String model;
  final String type;
  final double powerConsumption;
  final List<MachineMetricCreateItem> metrics;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serialNumber': serialNumber,
      'name': name,
      'manufacturer': manufacturer,
      'plantId': plantId,
      'model': model,
      'type': type,
      'powerConsumption': powerConsumption,
      'metrics': metrics.map((e) => e.toMap()).toList(),
    };
  }
}

class MachinesService {
  MachinesService(this._dio);

  final Dio _dio;

  Future<List<MachineItem>> getAllMachines() async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.machines);
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => MachineItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudo cargar maquinarias.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<List<MachineItem>> getAvailableMachines() async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.machines}/available');
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => MachineItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudieron cargar maquinarias disponibles.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<List<MachineItem>> getMaintenanceDueMachines() async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.machines}/maintenance-due');
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => MachineItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudieron cargar maquinarias con mantenimiento pendiente.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<List<MachineItem>> getMachinesByProductionLine(int lineId) async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiPaths.machines}/production-line/$lineId',
      );
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => MachineItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudieron cargar maquinarias de la linea.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<List<MachineItem>> getMachinesByPlant(int plantId) async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.machines}/plant/$plantId');
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => MachineItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudieron cargar maquinarias de la planta.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<MachineItem> register(RegisterMachineRequest request) async {
    try {
      final response = await _dio.post<dynamic>(ApiPaths.machines, data: request.toMap());
      return MachineItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            e.response?.data?.toString() ??
            'No se pudo registrar la maquinaria.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<void> assignToLine(int machineId, int productionLineId) async {
    try {
      await _dio.put<dynamic>(
        '${ApiPaths.machines}/$machineId/assign',
        data: <String, dynamic>{'productionLineId': productionLineId},
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudo asignar maquinaria.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<void> startMaintenance(int machineId) async {
    try {
      await _dio.put<dynamic>('${ApiPaths.machines}/$machineId/maintenance/start');
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudo iniciar mantenimiento.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<void> completeMaintenance(int machineId) async {
    try {
      await _dio.put<dynamic>('${ApiPaths.machines}/$machineId/maintenance/complete');
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudo completar mantenimiento.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCurrentMetrics(int machineId) async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/machines/$machineId/metrics');
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudieron cargar metricas de la maquina.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}
