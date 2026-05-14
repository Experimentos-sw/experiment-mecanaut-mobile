import 'package:flutter/foundation.dart';

class StaticPlanTaskDraft {
  StaticPlanTaskDraft({
    required this.description,
    required this.machineIds,
  });

  String description;
  List<int> machineIds;
}

class StaticPlanDayDraft {
  StaticPlanDayDraft({
    required this.dayNumber,
    required this.tasks,
  });

  int dayNumber;
  List<StaticPlanTaskDraft> tasks;
}

class StaticMaintenancePlanDraftController extends ChangeNotifier {
  String name = '';
  DateTime? startDate;
  int durationDays = 1;
  int repeatEveryWeeks = 1;
  int? productionLineId;
  List<int> selectedMachineIds = <int>[];
  final List<StaticPlanDayDraft> days = <StaticPlanDayDraft>[];
  bool hasChanges = false;

  void setGeneral({
    required String nameValue,
    required DateTime startDateValue,
    required int durationValue,
    required int repeatWeeksValue,
    required int lineId,
    required List<int> machineIds,
  }) {
    name = nameValue;
    startDate = startDateValue;
    durationDays = durationValue;
    repeatEveryWeeks = repeatWeeksValue;
    productionLineId = lineId;
    selectedMachineIds = machineIds;
    if (days.isEmpty) {
      for (var i = 1; i <= durationDays; i++) {
        days.add(
          StaticPlanDayDraft(
            dayNumber: i,
            tasks: <StaticPlanTaskDraft>[
              StaticPlanTaskDraft(description: 'Verificacion de niveles', machineIds: <int>[]),
            ],
          ),
        );
      }
    }
    hasChanges = true;
    notifyListeners();
  }

  void updateTask({
    required int day,
    required int taskIndex,
    required String description,
    required List<int> machineIds,
  }) {
    final draft = days.firstWhere((d) => d.dayNumber == day);
    draft.tasks[taskIndex]
      ..description = description
      ..machineIds = machineIds;
    hasChanges = true;
    notifyListeners();
  }

  void addTask(int day) {
    final draft = days.firstWhere((d) => d.dayNumber == day);
    draft.tasks.add(StaticPlanTaskDraft(description: '', machineIds: <int>[]));
    hasChanges = true;
    notifyListeners();
  }

  void clear() {
    name = '';
    startDate = null;
    durationDays = 1;
    repeatEveryWeeks = 1;
    productionLineId = null;
    selectedMachineIds = <int>[];
    days.clear();
    hasChanges = false;
    notifyListeners();
  }
}

