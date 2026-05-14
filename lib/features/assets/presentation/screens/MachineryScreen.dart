import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppBottomSheet.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/EmptyStateView.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/FilterChipGroup.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MetricDefinitionsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/PlantsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/MachineCard.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/NewMachineModal.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/PlantSelector.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/ProductionLineSelector.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

enum _MachineFilter { all, available, maintenanceDue }

class MachineryScreen extends ConsumerStatefulWidget {
  const MachineryScreen({super.key});

  @override
  ConsumerState<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends ConsumerState<MachineryScreen> {
  late final PlantsService _plantsService;
  late final ProductionLinesService _linesService;
  late final MachinesService _machinesService;
  late final MetricDefinitionsService _metricsService;

  bool _loading = true;
  String? _error;
  List<PlantItem> _plants = <PlantItem>[];
  List<ProductionLineItem> _lines = <ProductionLineItem>[];
  List<MachineItem> _machines = <MachineItem>[];
  List<MetricDefinitionItem> _metricDefinitions = <MetricDefinitionItem>[];
  int? _selectedPlantId;
  int? _selectedLineId;
  String _query = '';
  _MachineFilter _filter = _MachineFilter.all;

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _plantsService = PlantsService(dio);
    _linesService = ProductionLinesService(dio);
    _machinesService = MachinesService(dio);
    _metricsService = MetricDefinitionsService(dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await _plantsService.getPlants();
      final metrics = await _metricsService.getDefinitions();
      int? selectedPlant = _selectedPlantId;
      if (selectedPlant == null && plants.isNotEmpty) selectedPlant = plants.first.id;

      final lines = await _linesService.getProductionLines(plantId: selectedPlant);
      final machines = await _loadMachines(selectedPlant, _selectedLineId);
      setState(() {
        _plants = plants;
        _metricDefinitions = metrics;
        _selectedPlantId = selectedPlant;
        _lines = lines;
        _machines = machines;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<List<MachineItem>> _loadMachines(int? plantId, int? lineId) async {
    if (_filter == _MachineFilter.available) return _machinesService.getAvailableMachines();
    if (_filter == _MachineFilter.maintenanceDue) return _machinesService.getMaintenanceDueMachines();
    if (lineId != null) return _machinesService.getMachinesByProductionLine(lineId);
    if (plantId != null) return _machinesService.getMachinesByPlant(plantId);
    return _machinesService.getAllMachines();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Gestion de Maquinarias',
      currentRoute: '/gestion-maquinarias',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Cargando maquinarias...');
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    final filtered = _machines.where((machine) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return machine.model.toLowerCase().contains(q) ||
          machine.name.toLowerCase().contains(q) ||
          machine.serialNumber.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: <Widget>[
        _buildToolbar(),
        const SizedBox(height: 10),
        if (_plants.isNotEmpty)
          PlantSelector(
            plants: _plants,
            selectedPlantId: _selectedPlantId,
            onChanged: (value) async {
              setState(() {
                _selectedPlantId = value;
                _selectedLineId = null;
              });
              await _load();
            },
          ),
        const SizedBox(height: 8),
        ProductionLineSelector(
          lines: _lines,
          selectedLineId: _selectedLineId,
          onChanged: (value) async {
            setState(() => _selectedLineId = value);
            await _reloadMachines();
          },
          enabled: _selectedPlantId != null,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateView(title: 'Sin maquinarias', message: 'No hay resultados para los filtros actuales.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _machineCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final searchField = TextField(
      decoration: const InputDecoration(
        hintText: 'Buscar maquina...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (v) => setState(() => _query = v),
    );

    final filterButton = OutlinedButton.icon(
      onPressed: _openFilterSheet,
      icon: const Icon(Icons.filter_alt_outlined),
      label: const Text('Filtro'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
    );

    final createButton = ElevatedButton.icon(
      onPressed: _selectedPlantId == null ? null : _openNewMachineModal,
      icon: const Icon(Icons.add),
      label: const Text('Nueva Maquina'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 52)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(width: double.infinity, child: createButton),
              const SizedBox(height: 10),
              searchField,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: filterButton),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: searchField),
            const SizedBox(width: 10),
            SizedBox(width: 160, child: filterButton),
            const SizedBox(width: 10),
            SizedBox(width: 210, child: createButton),
          ],
        );
      },
    );
  }

  Widget _machineCard(MachineItem machine) {
    final plant = _plants.where((p) => p.id == _selectedPlantId).cast<PlantItem?>().firstOrNull;
    final line = _lines.where((l) => l.id == machine.productionLineId).cast<ProductionLineItem?>().firstOrNull;
    return MachineCard(
      machine: machine,
      plantLabel: plant?.name ?? '-',
      lineLabel: line?.name ?? 'Sin asignar',
      onStartMaintenance: () => _confirmMaintenance(machine, start: true),
      onCompleteMaintenance: () => _confirmMaintenance(machine, start: false),
      onAssignLine: () => _openAssignLine(machine),
      onDetailTap: () => _showMachineDetails(machine),
    );
  }

  Future<void> _reloadMachines() async {
    setState(() => _loading = true);
    try {
      final machines = await _loadMachines(_selectedPlantId, _selectedLineId);
      setState(() {
        _machines = machines;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => AppBottomSheet(
        title: 'Filtros',
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilterChipGroup<_MachineFilter>(
            selected: _filter,
            items: <FilterChipItem<_MachineFilter>>[
              FilterChipItem(value: _MachineFilter.all, label: 'Todos'),
              FilterChipItem(value: _MachineFilter.available, label: 'Disponibles'),
              FilterChipItem(value: _MachineFilter.maintenanceDue, label: 'Mantenimiento pendiente'),
            ],
            onSelected: (value) async {
              Navigator.of(context).pop();
              setState(() => _filter = value);
              await _reloadMachines();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openNewMachineModal() async {
    final result = await showModalBottomSheet<NewMachineModalResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        child: NewMachineModal(
          plantId: _selectedPlantId!,
          metricDefinitions: _metricDefinitions,
        ),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
    if (result == null) return;
    try {
      await _machinesService.register(result.toRequest());
      await _reloadMachines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maquinaria creada correctamente.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmMaintenance(MachineItem machine, {required bool start}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(start ? 'Iniciar mantenimiento' : 'Completar mantenimiento'),
        content: Text(start
            ? 'Se cambiara el estado de la maquina a mantenimiento.'
            : 'Se marcara el mantenimiento como completado.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (start) {
        await _machinesService.startMaintenance(machine.id);
      } else {
        await _machinesService.completeMaintenance(machine.id);
      }
      await _reloadMachines();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openAssignLine(MachineItem machine) async {
    int? selected = machine.productionLineId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Asignar a linea'),
          content: DropdownButtonFormField<int>(
            initialValue: selected,
            items: _lines.map((line) => DropdownMenuItem<int>(value: line.id, child: Text(line.name))).toList(),
            onChanged: (value) => selected = value,
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Guardar')),
          ],
        );
      },
    );
    if (confirmed != true || selected == null) return;
    try {
      await _machinesService.assignToLine(machine.id, selected!);
      await _reloadMachines();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _showMachineDetails(MachineItem machine) async {
    try {
      final metrics = await _machinesService.getCurrentMetrics(machine.id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AppBottomSheet(
          title: 'Detalle de maquinaria',
          onClose: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${machine.model} - ${machine.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Serie: ${machine.serialNumber}'),
                Text('Fabricante: ${machine.manufacturer}'),
                Text('Tipo: ${machine.type}'),
                Text('Estado: ${machine.status}'),
                const SizedBox(height: 10),
                const Text('Metricas actuales', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (metrics.isEmpty)
                  const Text('Sin metricas registradas')
                else
                  ...metrics.map(
                    (m) => Text(
                      '${m['metricName'] ?? m['name'] ?? 'Metrica'}: ${m['value'] ?? '-'} ${m['unit'] ?? ''}',
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
