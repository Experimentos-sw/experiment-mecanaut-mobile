enum CalendarEventSource { workOrder, maintenancePlan, executedWorkOrder }

class CalendarEventItem {
  CalendarEventItem({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
    required this.date,
    required this.productionLineId,
    required this.source,
    this.timeLabel,
    this.notes,
  });

  final String id;
  final String title;
  final String status;
  final String type;
  final DateTime date;
  final int productionLineId;
  final CalendarEventSource source;
  final String? timeLabel;
  final String? notes;
}
