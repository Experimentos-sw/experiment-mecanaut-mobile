import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/calendar/data/models/calendar_event_item.dart';
import 'package:mecanaut_mobile/features/work_orders/data/models/work_order_item.dart';
import 'package:mecanaut_mobile/features/work_orders/data/services/WorkOrdersService.dart';

class CalendarService {
  CalendarService(this._dio, this._workOrdersService);

  final Dio _dio;
  final WorkOrdersService _workOrdersService;

  Future<List<CalendarEventItem>> loadEventsByProductionLine(int lineId) async {
    try {
      final List<CalendarEventItem> events = <CalendarEventItem>[];
      final workOrders = await _workOrdersService.getByProductionLine(lineId);
      events.addAll(workOrders.where((wo) => wo.date != null).map(_mapWorkOrder));
      try {
        final dynamicPlans = await _dio.get<dynamic>(
          ApiPaths.dynamicMaintenancePlans,
          queryParameters: <String, dynamic>{'plantLineId': lineId},
        );
        final plans = dynamicPlans.data as List<dynamic>? ?? <dynamic>[];
        if (plans.isNotEmpty) {
        }
      } catch (_) {
      }
      try {
        final executed = await _dio.get<dynamic>('/api/v1/executed-work-orders/production-line/$lineId');
        final list = executed.data as List<dynamic>? ?? <dynamic>[];
        events.addAll(
          list
              .where((e) => e is Map<String, dynamic> && e['executionDate'] != null)
              .map((dynamic raw) => raw as Map<String, dynamic>)
              .map(
                (map) => CalendarEventItem(
                  id: 'EX-${map['id']}',
                  title: map['code']?.toString() ?? 'Orden ejecutada',
                  status: 'Completed',
                  type: 'Executed',
                  date: DateTime.parse(map['executionDate'].toString()),
                  productionLineId: (map['productionLineId'] as num?)?.toInt() ?? lineId,
                  source: CalendarEventSource.executedWorkOrder,
                  timeLabel: 'Historial',
                ),
              ),
        );
      } catch (_) {
      }

      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'No se pudo construir el calendario.', details: e);
    }
  }

  CalendarEventItem _mapWorkOrder(WorkOrderItem wo) {
    return CalendarEventItem(
      id: wo.id.toString(),
      title: wo.code,
      status: wo.status,
      type: wo.type,
      date: wo.date!,
      productionLineId: wo.productionLineId,
      source: CalendarEventSource.workOrder,
      notes: wo.tasks.join(', '),
      timeLabel: '08:00 - 10:00',
    );
  }
}
