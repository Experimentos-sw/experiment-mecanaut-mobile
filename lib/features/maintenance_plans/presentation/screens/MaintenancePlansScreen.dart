import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppBottomSheet.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/EmptyStateView.dart';
import 'package:mecanaut_mobile/core/widgets/EntityCard.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MetricDefinitionsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/PlantsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/dynamic_maintenance_plan_dto.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/services/DynamicMaintenancePlansService.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/presentation/screens/wizard/NewDynamicPlanWizard.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/create_experiment_survey_request.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/services/ExperimentSurveysService.dart';

class MaintenancePlansScreen extends ConsumerStatefulWidget {
  const MaintenancePlansScreen({super.key});

  @override
  ConsumerState<MaintenancePlansScreen> createState() => _MaintenancePlansScreenState();
}

class _MaintenancePlansScreenState extends ConsumerState<MaintenancePlansScreen> {
  late final PlantsService _plantsService;
  late final ProductionLinesService _linesService;
  late final MachinesService _machinesService;
  late final MetricDefinitionsService _metricsService;
  late final DynamicMaintenancePlansService _dynamicPlansService;
  late final ExperimentSurveysService _surveysService;

  bool _loading = true;
  String? _error;
  String _query = '';

  List<PlantItem> _plants = <PlantItem>[];
  List<ProductionLineItem> _lines = <ProductionLineItem>[];
  List<MachineItem> _machines = <MachineItem>[];
  List<MetricDefinitionItem> _metricDefinitions = <MetricDefinitionItem>[];
  List<DynamicMaintenancePlanDto> _plans = <DynamicMaintenancePlanDto>[];

  int? _selectedPlantId;
  int? _selectedLineId;
  String? _selectedMetricFilterId;

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _plantsService = PlantsService(dio);
    _linesService = ProductionLinesService(dio);
    _machinesService = MachinesService(dio);
    _metricsService = MetricDefinitionsService(dio);
    _dynamicPlansService = DynamicMaintenancePlansService(dio);
    _surveysService = ExperimentSurveysService(dio);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await _plantsService.getPlants();
      final metrics = await _metricsService.getDefinitions();

      int? plantId = _selectedPlantId;
      if (plantId == null && plants.isNotEmpty) {
        plantId = plants.first.id;
      }

      List<ProductionLineItem> lines = <ProductionLineItem>[];
      if (plantId != null) {
        lines = await _linesService.getProductionLines(plantId: plantId);
      }

      int? lineId = _selectedLineId;
      if (lineId != null && !lines.any((line) => line.id == lineId)) {
        lineId = null;
      }
      if (lineId == null && lines.isNotEmpty) {
        lineId = lines.first.id;
      }

      List<MachineItem> machines = <MachineItem>[];
      List<DynamicMaintenancePlanDto> plans = <DynamicMaintenancePlanDto>[];
      if (plantId != null) {
        machines = await _machinesService.getMachinesByPlant(plantId);
      }
      if (lineId != null) {
        plans = await _dynamicPlansService.getByPlantLine(lineId.toString());
      }

      setState(() {
        _plants = plants;
        _metricDefinitions = metrics;
        _selectedPlantId = plantId;
        _lines = lines;
        _selectedLineId = lineId;
        _machines = machines;
        _plans = plans;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo cargar planes de mantenimiento.';
        _loading = false;
      });
    }
  }

  Future<void> _reloadPlansForSelectedLine() async {
    if (_selectedLineId == null) {
      setState(() => _plans = <DynamicMaintenancePlanDto>[]);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await _dynamicPlansService.getByPlantLine(_selectedLineId.toString());
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Planes de Mantenimiento',
      currentRoute: '/plan-mantenimiento',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Cargando planes...');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _loadInitial);
    }

    final visiblePlans = _filteredPlans();

    return Column(
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar plan...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openFilterSheet,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Filtro'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openNewPlanModal,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Plan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: visiblePlans.isEmpty
              ? const EmptyStateView(
                  title: 'Sin planes',
                  message: 'No hay planes de mantenimiento registrados.',
                )
              : ListView.separated(
                  itemCount: visiblePlans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, int index) => _planCard(visiblePlans[index]),
                ),
        ),
      ],
    );
  }

  List<DynamicMaintenancePlanDto> _filteredPlans() {
    return _plans.where((plan) {
      final q = _query.trim().toLowerCase();
      final metricName = _metricName(plan.metricId).toLowerCase();
      final matchesQuery = q.isEmpty ||
          plan.id.toLowerCase().contains(q) ||
          plan.name.toLowerCase().contains(q) ||
          plan.metricId.toLowerCase().contains(q) ||
          metricName.contains(q) ||
          plan.amount.toLowerCase().contains(q);
      if (!matchesQuery) return false;
      if (_selectedMetricFilterId != null && _selectedMetricFilterId!.isNotEmpty) {
        return plan.metricId == _selectedMetricFilterId;
      }
      return true;
    }).toList();
  }

  Widget _planCard(DynamicMaintenancePlanDto plan) {
    final amountText = _amountText(plan);
    return EntityCard(
      badge: Text(
        'ID: ${plan.id}',
        style: const TextStyle(color: Color(0xFF7E879A), fontSize: 12),
      ),
      title: plan.name,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _rowValue('Parametro', _metricName(plan.metricId)),
          const SizedBox(height: 6),
          _rowValue('Mantenimiento cada', amountText),
          const SizedBox(height: 6),
          _rowValue('Acciones', 'Ver detalle'),
        ],
      ),
      actions: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _showPlanDetail(plan),
          child: const Text('Ver'),
        ),
      ),
    );
  }

  Widget _rowValue(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFF7E879A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF252E3E),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  String _metricName(String metricId) {
    final match = _metricDefinitions.where((m) => m.id.toString() == metricId).cast<MetricDefinitionItem?>().firstOrNull;
    if (match == null || match.name.trim().isEmpty) return metricId;
    return match.name;
  }

  String _amountText(DynamicMaintenancePlanDto plan) {
    final metric = _metricDefinitions.where((m) => m.id.toString() == plan.metricId).cast<MetricDefinitionItem?>().firstOrNull;
    final unit = metric?.unit.trim() ?? '';
    if (unit.isEmpty) return plan.amount;
    return '${plan.amount} $unit';
  }

  Future<void> _openFilterSheet() async {
    final selectedPlant = _selectedPlantId;
    final selectedLine = _selectedLineId;
    final selectedMetric = _selectedMetricFilterId;

    final result = await showModalBottomSheet<_PlansFilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: 'Filtro',
        onClose: () => Navigator.of(context).pop(),
        child: _PlansFilterSheet(
          plants: _plants,
          lines: _lines,
          metrics: _metricDefinitions,
          selectedPlantId: selectedPlant,
          selectedLineId: selectedLine,
          selectedMetricId: selectedMetric,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _selectedMetricFilterId = result.metricId;
    });

    if (result.plantId != _selectedPlantId) {
      setState(() {
        _selectedPlantId = result.plantId;
        _selectedLineId = null;
      });
      await _reloadPlantScope();
    } else if (result.lineId != _selectedLineId) {
      setState(() => _selectedLineId = result.lineId);
      await _reloadPlansForSelectedLine();
    }
  }

  Future<void> _reloadPlantScope() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lines = _selectedPlantId == null
          ? <ProductionLineItem>[]
          : await _linesService.getProductionLines(plantId: _selectedPlantId);
      int? lineId = _selectedLineId;
      if (lineId == null && lines.isNotEmpty) {
        lineId = lines.first.id;
      }
      final machines = _selectedPlantId == null
          ? <MachineItem>[]
          : await _machinesService.getMachinesByPlant(_selectedPlantId!);
      final plans = lineId == null
          ? <DynamicMaintenancePlanDto>[]
          : await _dynamicPlansService.getByPlantLine(lineId.toString());

      setState(() {
        _lines = lines;
        _selectedLineId = lineId;
        _machines = machines;
        _plans = plans;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openNewPlanModal() async {
    final result = await showModalBottomSheet<SaveDynamicMaintenancePlanRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: 'Nuevo Plan',
        onClose: () => Navigator.of(context).pop(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: NewDynamicPlanWizard(
            plants: _plants,
            initialPlantId: _selectedPlantId,
            linesService: _linesService,
            machinesService: _machinesService,
            metricDefinitions: _metricDefinitions,
          ),
        ),
      ),
    );

    if (result == null) {
      if (mounted) await _showSurveyDialog(finished: false, planId: 0);
      return;
    }
    
    try {
      final plan = await _dynamicPlansService.create(result);
      await _reloadPlansForSelectedLine();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan de mantenimiento creado correctamente.')),
        );
        int planId = int.tryParse(plan.id) ?? 0;
        await _showSurveyDialog(finished: true, planId: planId);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _showSurveyDialog({required bool finished, required int planId}) async {
    int rating = 0;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Breve encuesta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Qué tan fácil fue usar este asistente?'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios adicionales (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Omitir'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await _surveysService.create(
                        CreateExperimentSurveyRequest(
                          maintenancePlanId: planId,
                          rating: rating > 0 ? rating : 3,
                          variant: 'wizard',
                          action: finished ? 'finished' : 'abandoned',
                          comment: commentController.text,
                        )
                      );
                    } catch (_) {
                      // Silently fail telemetry
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showPlanDetail(DynamicMaintenancePlanDto plan) {
    final machineLabels = _machines
        .where((m) => plan.machineIds.contains(m.id))
        .map((m) => m.model.isNotEmpty ? m.model : m.name)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: 'Detalle del Plan',
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _detailRow('ID', plan.id),
              _detailRow('Nombre', plan.name),
              _detailRow('Parametro', _metricName(plan.metricId)),
              _detailRow('Mantenimiento cada', _amountText(plan)),
              _detailRow(
                'Maquinas',
                machineLabels.isEmpty ? plan.machineIds.join(', ') : machineLabels.join(', '),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tareas',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF252E3E),
                ),
              ),
              const SizedBox(height: 6),
              if (plan.taskDescriptions.isEmpty)
                const Text('Sin tareas registradas.')
              else
                ...plan.taskDescriptions.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $task'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF7E879A),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PlansFilterResult {
  const _PlansFilterResult({
    required this.plantId,
    required this.lineId,
    required this.metricId,
  });

  final int? plantId;
  final int? lineId;
  final String? metricId;
}

class _PlansFilterSheet extends StatefulWidget {
  const _PlansFilterSheet({
    required this.plants,
    required this.lines,
    required this.metrics,
    required this.selectedPlantId,
    required this.selectedLineId,
    required this.selectedMetricId,
  });

  final List<PlantItem> plants;
  final List<ProductionLineItem> lines;
  final List<MetricDefinitionItem> metrics;
  final int? selectedPlantId;
  final int? selectedLineId;
  final String? selectedMetricId;

  @override
  State<_PlansFilterSheet> createState() => _PlansFilterSheetState();
}

class _PlansFilterSheetState extends State<_PlansFilterSheet> {
  late int? _plantId;
  late int? _lineId;
  late String? _metricId;

  @override
  void initState() {
    super.initState();
    _plantId = widget.selectedPlantId;
    _lineId = widget.selectedLineId;
    _metricId = widget.selectedMetricId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButtonFormField<int?>(
            initialValue: _plantId,
            decoration: const InputDecoration(labelText: 'Planta'),
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
              ...widget.plants.map((plant) => DropdownMenuItem<int?>(
                    value: plant.id,
                    child: Text(plant.name),
                  )),
            ],
            onChanged: (value) => setState(() => _plantId = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: _lineId,
            decoration: const InputDecoration(labelText: 'Linea de produccion'),
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
              ...widget.lines.map((line) => DropdownMenuItem<int?>(
                    value: line.id,
                    child: Text(line.name),
                  )),
            ],
            onChanged: (value) => setState(() => _lineId = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: _metricId,
            decoration: const InputDecoration(labelText: 'Parametro'),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              ...widget.metrics.map((metric) => DropdownMenuItem<String?>(
                    value: metric.id.toString(),
                    child: Text(metric.name),
                  )),
            ],
            onChanged: (value) => setState(() => _metricId = value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _PlansFilterResult(
                    plantId: _plantId,
                    lineId: _lineId,
                    metricId: _metricId,
                  ),
                );
              },
              child: const Text('Aplicar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewDynamicPlanSheet extends StatefulWidget {
  const _NewDynamicPlanSheet({
    required this.plants,
    required this.initialPlantId,
    required this.linesService,
    required this.machinesService,
    required this.metricDefinitions,
  });

  final List<PlantItem> plants;
  final int? initialPlantId;
  final ProductionLinesService linesService;
  final MachinesService machinesService;
  final List<MetricDefinitionItem> metricDefinitions;

  @override
  State<_NewDynamicPlanSheet> createState() => _NewDynamicPlanSheetState();
}

class _NewDynamicPlanSheetState extends State<_NewDynamicPlanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '100');
  final List<TextEditingController> _taskControllers = <TextEditingController>[
    TextEditingController(),
  ];

  int? _plantId;
  int? _lineId;
  String? _metricId;
  List<ProductionLineItem> _lines = <ProductionLineItem>[];
  List<MachineItem> _machines = <MachineItem>[];
  final Set<int> _selectedMachineIds = <int>{};
  bool _loadingScope = false;

  @override
  void initState() {
    super.initState();
    _plantId = widget.initialPlantId ?? (widget.plants.isEmpty ? null : widget.plants.first.id);
    _metricId = widget.metricDefinitions.isEmpty ? null : widget.metricDefinitions.first.id.toString();
    _loadScope();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    for (final controller in _taskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadScope() async {
    if (_plantId == null) {
      setState(() {
        _lines = <ProductionLineItem>[];
        _lineId = null;
        _machines = <MachineItem>[];
        _selectedMachineIds.clear();
      });
      return;
    }

    setState(() => _loadingScope = true);
    try {
      final lines = await widget.linesService.getProductionLines(plantId: _plantId);
      int? lineId = _lineId;
      if (lineId == null && lines.isNotEmpty) {
        lineId = lines.first.id;
      }
      if (lineId != null && !lines.any((line) => line.id == lineId)) {
        lineId = lines.isEmpty ? null : lines.first.id;
      }

      final plantMachines = await widget.machinesService.getMachinesByPlant(_plantId!);
      final visibleMachines = lineId == null
          ? plantMachines
          : plantMachines.where((machine) => machine.productionLineId == lineId).toList();

      _selectedMachineIds.removeWhere((id) => !visibleMachines.any((m) => m.id == id));
      if (_selectedMachineIds.isEmpty && visibleMachines.isNotEmpty) {
        _selectedMachineIds.add(visibleMachines.first.id);
      }

      setState(() {
        _lines = lines;
        _lineId = lineId;
        _machines = visibleMachines;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loadingScope = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _plantId,
                decoration: const InputDecoration(labelText: 'Planta'),
                items: widget.plants
                    .map((plant) => DropdownMenuItem<int>(value: plant.id, child: Text(plant.name)))
                    .toList(),
                onChanged: (value) async {
                  setState(() {
                    _plantId = value;
                    _lineId = null;
                  });
                  await _loadScope();
                },
                validator: (v) => v == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _lineId,
                decoration: const InputDecoration(labelText: 'Linea de produccion'),
                items: _lines
                    .map((line) => DropdownMenuItem<int>(value: line.id, child: Text('${line.name} (${line.code})')))
                    .toList(),
                onChanged: (value) async {
                  setState(() => _lineId = value);
                  await _loadScope();
                },
                validator: (v) => v == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _metricId,
                decoration: const InputDecoration(labelText: 'Parametro'),
                items: widget.metricDefinitions
                    .map((metric) => DropdownMenuItem<String>(
                          value: metric.id.toString(),
                          child: Text(metric.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _metricId = value),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Mantenimiento cada'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'Valor invalido';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Maquinas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (_loadingScope)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_machines.isEmpty)
                const Text('No hay maquinas disponibles para la linea seleccionada.')
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _machines.map((machine) {
                    final selected = _selectedMachineIds.contains(machine.id);
                    final label = machine.model.isNotEmpty ? machine.model : machine.name;
                    return FilterChip(
                      selected: selected,
                      label: Text(label),
                      onSelected: (on) {
                        setState(() {
                          if (on) {
                            _selectedMachineIds.add(machine.id);
                          } else {
                            _selectedMachineIds.remove(machine.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              const Text(
                'Tareas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ..._taskControllers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(labelText: 'Tarea ${entry.key + 1}'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _taskControllers.length == 1
                            ? null
                            : () {
                                setState(() {
                                  final controller = _taskControllers.removeAt(entry.key);
                                  controller.dispose();
                                });
                              },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _taskControllers.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar tarea'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Guardar'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El flujo de plan estatico queda pendiente porque el backend publico no expone endpoint especifico.'),
                    ),
                  );
                },
                child: const Text('Nuevo plan estatico (pendiente)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_lineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una linea de produccion.')));
      return;
    }
    if (_selectedMachineIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos una maquina.')));
      return;
    }
    final tasks = _taskControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos una tarea.')));
      return;
    }

    final request = SaveDynamicMaintenancePlanRequest(
      name: _nameController.text.trim(),
      metricId: _metricId!,
      amount: _amountController.text.trim(),
      productionLineId: _lineId.toString(),
      plantLineId: _lineId.toString(),
      machines: _selectedMachineIds.toList(),
      tasks: tasks,
    );

    Navigator.of(context).pop(request);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
