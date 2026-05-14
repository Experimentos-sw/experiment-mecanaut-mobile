import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/EmptyStateView.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachineMetricsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MetricDefinitionsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/PlantsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

class MachineMetricsScreen extends ConsumerStatefulWidget {
  const MachineMetricsScreen({super.key});

  @override
  ConsumerState<MachineMetricsScreen> createState() => _MachineMetricsScreenState();
}

class _MachineMetricsScreenState extends ConsumerState<MachineMetricsScreen> {
  late final PlantsService _plantsService;
  late final ProductionLinesService _linesService;
  late final MachinesService _machinesService;
  late final MetricDefinitionsService _definitionsService;
  late final MachineMetricsService _metricsService;

  bool _loading = true;
  String? _error;

  List<PlantItem> _plants = <PlantItem>[];
  List<ProductionLineItem> _lines = <ProductionLineItem>[];
  List<MachineItem> _machines = <MachineItem>[];
  List<MetricDefinitionItem> _definitions = <MetricDefinitionItem>[];
  List<MachineMetricItem> _metrics = <MachineMetricItem>[];
  final Map<int, TextEditingController> _valueControllers = <int, TextEditingController>{};
  final Map<int, String> _metricErrors = <int, String>{};
  final Set<int> _savingMetricIds = <int>{};

  int? _selectedPlantId;
  int? _selectedLineId;
  int? _selectedMachineId;

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _plantsService = PlantsService(dio);
    _linesService = ProductionLinesService(dio);
    _machinesService = MachinesService(dio);
    _definitionsService = MetricDefinitionsService(dio);
    _metricsService = MachineMetricsService(dio);
    _loadInitial();
  }

  @override
  void dispose() {
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await _plantsService.getPlants();
      final definitions = await _definitionsService.getDefinitions();

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
      if (lineId != null) {
        machines = await _machinesService.getMachinesByProductionLine(lineId);
      }

      int? machineId = _selectedMachineId;
      if (machineId != null && !machines.any((machine) => machine.id == machineId)) {
        machineId = null;
      }
      if (machineId == null && machines.isNotEmpty) {
        machineId = machines.first.id;
      }

      List<MachineMetricItem> metrics = <MachineMetricItem>[];
      if (machineId != null) {
        metrics = await _metricsService.getMachineMetrics(machineId);
      }

      _syncValueControllers(metrics);

      setState(() {
        _plants = plants;
        _definitions = definitions;
        _selectedPlantId = plantId;
        _lines = lines;
        _selectedLineId = lineId;
        _machines = machines;
        _selectedMachineId = machineId;
        _metrics = metrics;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _syncValueControllers(List<MachineMetricItem> metrics) {
    final currentIds = metrics.map((m) => m.metricId).toSet();
    final obsolete = _valueControllers.keys.where((id) => !currentIds.contains(id)).toList();
    for (final id in obsolete) {
      _valueControllers[id]?.dispose();
      _valueControllers.remove(id);
      _metricErrors.remove(id);
      _savingMetricIds.remove(id);
    }
    for (final metric in metrics) {
      _valueControllers.putIfAbsent(metric.metricId, TextEditingController.new);
    }
  }

  Future<void> _onPlantChanged(int? plantId) async {
    setState(() {
      _selectedPlantId = plantId;
      _selectedLineId = null;
      _selectedMachineId = null;
      _lines = <ProductionLineItem>[];
      _machines = <MachineItem>[];
      _metrics = <MachineMetricItem>[];
      _error = null;
      _loading = true;
    });
    try {
      List<ProductionLineItem> lines = <ProductionLineItem>[];
      if (plantId != null) {
        lines = await _linesService.getProductionLines(plantId: plantId);
      }
      int? lineId = lines.isEmpty ? null : lines.first.id;
      List<MachineItem> machines = <MachineItem>[];
      if (lineId != null) {
        machines = await _machinesService.getMachinesByProductionLine(lineId);
      }
      int? machineId = machines.isEmpty ? null : machines.first.id;
      List<MachineMetricItem> metrics = <MachineMetricItem>[];
      if (machineId != null) {
        metrics = await _metricsService.getMachineMetrics(machineId);
      }
      _syncValueControllers(metrics);
      setState(() {
        _lines = lines;
        _selectedLineId = lineId;
        _machines = machines;
        _selectedMachineId = machineId;
        _metrics = metrics;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _onLineChanged(int? lineId) async {
    setState(() {
      _selectedLineId = lineId;
      _selectedMachineId = null;
      _machines = <MachineItem>[];
      _metrics = <MachineMetricItem>[];
      _error = null;
      _loading = true;
    });
    try {
      List<MachineItem> machines = <MachineItem>[];
      if (lineId != null) {
        machines = await _machinesService.getMachinesByProductionLine(lineId);
      }
      int? machineId = machines.isEmpty ? null : machines.first.id;
      List<MachineMetricItem> metrics = <MachineMetricItem>[];
      if (machineId != null) {
        metrics = await _metricsService.getMachineMetrics(machineId);
      }
      _syncValueControllers(metrics);
      setState(() {
        _machines = machines;
        _selectedMachineId = machineId;
        _metrics = metrics;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _onMachineChanged(int? machineId) async {
    setState(() {
      _selectedMachineId = machineId;
      _metrics = <MachineMetricItem>[];
      _error = null;
      _loading = true;
    });
    try {
      List<MachineMetricItem> metrics = <MachineMetricItem>[];
      if (machineId != null) {
        metrics = await _metricsService.getMachineMetrics(machineId);
      }
      _syncValueControllers(metrics);
      setState(() {
        _metrics = metrics;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _updateMetric(MachineMetricItem metric) async {
    if (_selectedMachineId == null) return;
    final controller = _valueControllers[metric.metricId];
    final raw = controller?.text.trim() ?? '';
    if (raw.isEmpty) {
      setState(() => _metricErrors[metric.metricId] = 'Ingresa un valor.');
      return;
    }
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) {
      setState(() => _metricErrors[metric.metricId] = 'El valor debe ser numerico.');
      return;
    }

    setState(() {
      _metricErrors.remove(metric.metricId);
      _savingMetricIds.add(metric.metricId);
    });

    try {
      await _metricsService.updateMachineMetric(
        _selectedMachineId!,
        UpdateMachineMetricRequest(
          metricId: metric.metricId,
          value: parsed,
          measuredAt: DateTime.now(),
        ),
      );
      final refreshed = await _metricsService.getMachineMetrics(_selectedMachineId!);
      _syncValueControllers(refreshed);
      controller?.clear();
      setState(() {
        _metrics = refreshed;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metrica actualizada correctamente.')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _metricErrors[metric.metricId] = e.message);
    } finally {
      if (mounted) {
        setState(() => _savingMetricIds.remove(metric.metricId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Metricas de Maquina',
      currentRoute: '/machine-metrics',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Cargando metricas...');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _loadInitial);
    }
    if (_plants.isEmpty) {
      return const EmptyStateView(
        title: 'Sin plantas',
        message: 'No hay plantas registradas.',
      );
    }
    if (_selectedPlantId == null) {
      return const EmptyStateView(
        title: 'Sin seleccion',
        message: 'Selecciona una planta.',
      );
    }
    if (_lines.isEmpty) {
      return const EmptyStateView(
        title: 'Sin lineas',
        message: 'No hay lineas para esta planta.',
      );
    }
    if (_selectedLineId == null) {
      return const EmptyStateView(
        title: 'Sin seleccion',
        message: 'Selecciona una linea de produccion.',
      );
    }
    if (_machines.isEmpty) {
      return const EmptyStateView(
        title: 'Sin maquinarias',
        message: 'No hay maquinarias para esta linea.',
      );
    }
    if (_selectedMachineId == null) {
      return const EmptyStateView(
        title: 'Sin seleccion',
        message: 'Selecciona una maquinaria.',
      );
    }

    final selectedMachine = _machines.where((m) => m.id == _selectedMachineId).cast<MachineItem?>().firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Metricas de Maquina',
          style: TextStyle(
            color: Color(0xFF1F56A0),
            fontSize: 32 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gestiona las metricas operativas de tus maquinarias.',
          style: TextStyle(color: Color(0xFF565E6D)),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: _selectedPlantId,
          decoration: const InputDecoration(labelText: 'Planta'),
          items: _plants
              .map((plant) => DropdownMenuItem<int>(value: plant.id, child: Text(plant.name)))
              .toList(),
          onChanged: _onPlantChanged,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: _selectedLineId,
          decoration: const InputDecoration(labelText: 'Linea de Produccion'),
          items: _lines
              .map((line) => DropdownMenuItem<int>(value: line.id, child: Text(line.name)))
              .toList(),
          onChanged: _onLineChanged,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: _selectedMachineId,
          decoration: const InputDecoration(labelText: 'Maquinaria'),
          items: _machines
              .map((machine) => DropdownMenuItem<int>(value: machine.id, child: Text(machine.name)))
              .toList(),
          onChanged: _onMachineChanged,
        ),
        const SizedBox(height: 12),
        Text(
          'Metricas de ${selectedMachine?.name ?? '-'}',
          style: const TextStyle(
            color: Color(0xFF1F56A0),
            fontSize: 30 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _metrics.isEmpty
              ? const EmptyStateView(
                  title: 'Sin metricas',
                  message: 'No hay metricas para esta maquinaria.',
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: _metrics.length,
                  itemBuilder: (_, index) => _metricCard(_metrics[index]),
                ),
        ),
      ],
    );
  }

  Widget _metricCard(MachineMetricItem metric) {
    final controller = _valueControllers[metric.metricId]!;
    final saving = _savingMetricIds.contains(metric.metricId);
    final measured = metric.measuredAt == null
        ? 'Sin datos'
        : DateFormat('d/M/y, HH:mm:ss').format(metric.measuredAt!.toLocal());
    final unit = metric.unit.trim().isEmpty ? '-' : metric.unit;
    final value = metric.value == null ? 'Sin datos' : metric.value.toString();
    final resolvedName = metric.metricName.trim().isNotEmpty
        ? metric.metricName
        : _definitions
                .where((d) => d.id == metric.metricId)
                .cast<MetricDefinitionItem?>()
                .firstOrNull
                ?.name ??
            'Metrica ${metric.metricId}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  resolvedName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF252E3E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE2ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: Color(0xFF2A3140),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Valor actual: $value', style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
            'Ultima medicion: $measured',
            style: const TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Actualizar valor:',
            style: TextStyle(
              color: Color(0xFF565E6D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Nuevo valor',
            ),
          ),
          if (_metricErrors[metric.metricId] != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              _metricErrors[metric.metricId]!,
              style: const TextStyle(color: Color(0xFFD7465E), fontSize: 11.5),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : () => _updateMetric(metric),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Actualizar'),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
