import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MetricDefinitionsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/dynamic_maintenance_plan_dto.dart';

class NewDynamicPlanWizard extends StatefulWidget {
  const NewDynamicPlanWizard({
    super.key,
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
  State<NewDynamicPlanWizard> createState() => _NewDynamicPlanWizardState();
}

class _NewDynamicPlanWizardState extends State<NewDynamicPlanWizard> {
  int _currentStep = 0;

  // Form State
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '100');
  List<TextEditingController> _taskControllers = [TextEditingController()];

  String? _metricId;
  int? _plantId;
  int? _lineId;
  Set<int> _selectedMachineIds = {};
  
  List<ProductionLineItem> _lines = [];
  List<MachineItem> _machines = [];
  bool _loadingScope = false;

  @override
  void initState() {
    super.initState();
    _plantId = widget.initialPlantId ?? (widget.plants.isEmpty ? null : widget.plants.first.id);
    _metricId = widget.metricDefinitions.isEmpty ? null : widget.metricDefinitions.first.id.toString();
    
    // Add listeners to rebuild KPIs on change
    _amountController.addListener(() => setState(() {}));
    _loadScope();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    for (var c in _taskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadScope() async {
    if (_plantId == null) {
      setState(() {
        _lines = [];
        _lineId = null;
        _machines = [];
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

  double get mtbf {
    int parsedMetric = int.tryParse(_metricId ?? '1') ?? 1;
    double parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    int machineCount = _selectedMachineIds.length;
    double val = 500.0 + (parsedMetric * 12.5) + (parsedAmount * 0.05) - (machineCount * 8.0);
    return max(24.0, val);
  }

  double get mttr {
    double parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    int machineCount = _selectedMachineIds.length;
    int taskCount = _taskControllers.length;
    double val = 4.0 + (machineCount * 1.2) - (parsedAmount * 0.001) + (taskCount * 1.5);
    return max(1.0, val);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // KPI Projection Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKpiItem('MTBF Proyectado', '${mtbf.toStringAsFixed(1)} h', Icons.access_time, Colors.green),
                _buildKpiItem('MTTR Proyectado', '${mttr.toStringAsFixed(1)} h', Icons.build, Colors.orange),
              ],
            ),
          ),
          
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un nombre para continuar')));
                  return;
                }
                if (_currentStep == 1 && double.tryParse(_amountController.text.trim()) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una frecuencia válida')));
                  return;
                }
                if (_currentStep == 2 && (_lineId == null || _selectedMachineIds.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona línea y maquinaria')));
                  return;
                }
                if (_currentStep == 3 && _taskControllers.every((c) => c.text.trim().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa al menos una tarea')));
                  return;
                }
                
                if (_currentStep < 4) {
                  setState(() => _currentStep += 1);
                } else {
                  _submit();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(_currentStep == 4 ? 'Guardar Plan' : 'Siguiente'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: Text(_currentStep == 0 ? 'Cancelar' : 'Atrás'),
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Nombre del plan'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                ),
                Step(
                  title: const Text('Parámetros y Frecuencia'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _metricId,
                        decoration: const InputDecoration(labelText: 'Parámetro'),
                        items: widget.metricDefinitions
                            .map((m) => DropdownMenuItem(value: m.id.toString(), child: Text(m.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _metricId = v),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: 'Mantenimiento cada'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Ubicación y Maquinaria'),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _plantId,
                        decoration: const InputDecoration(labelText: 'Planta'),
                        items: widget.plants
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                            .toList(),
                        onChanged: (v) async {
                          setState(() {
                            _plantId = v;
                            _lineId = null;
                          });
                          await _loadScope();
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _lineId,
                        decoration: const InputDecoration(labelText: 'Línea de producción'),
                        items: _lines
                            .map((l) => DropdownMenuItem(value: l.id, child: Text('${l.name} (${l.code})')))
                            .toList(),
                        onChanged: (v) async {
                          setState(() => _lineId = v);
                          await _loadScope();
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('Maquinaria', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (_loadingScope) const LinearProgressIndicator(),
                      if (!_loadingScope && _machines.isEmpty) const Text('No hay máquinas disponibles.'),
                      Wrap(
                        spacing: 6,
                        children: _machines.map((m) {
                          final selected = _selectedMachineIds.contains(m.id);
                          final label = m.model.isNotEmpty ? m.model : m.name;
                          return FilterChip(
                            selected: selected,
                            label: Text(label),
                            onSelected: (on) {
                              setState(() {
                                if (on) _selectedMachineIds.add(m.id);
                                else _selectedMachineIds.remove(m.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Tareas'),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      ..._taskControllers.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(labelText: 'Tarea ${entry.key + 1}'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              onPressed: _taskControllers.length > 1
                                  ? () => setState(() {
                                        _taskControllers.removeAt(entry.key).dispose();
                                      })
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            )
                          ],
                        ),
                      )),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _taskControllers.add(TextEditingController())),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar tarea'),
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Resumen'),
                  isActive: _currentStep >= 4,
                  state: StepState.indexed,
                  content: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryRow('Nombre', _nameController.text),
                        _summaryRow('Parámetro', _getMetricName()),
                        _summaryRow('Frecuencia', _amountController.text),
                        _summaryRow('Línea', _getLineName()),
                        _summaryRow('Máquinas', '${_selectedMachineIds.length} seleccionadas'),
                        _summaryRow('Tareas', '${_taskControllers.where((t) => t.text.trim().isNotEmpty).length} registradas'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getMetricName() {
    final matches = widget.metricDefinitions.where((m) => m.id.toString() == _metricId);
    return matches.isNotEmpty ? matches.first.name : (_metricId ?? '');
  }

  String _getLineName() {
    final matches = _lines.where((l) => l.id == _lineId);
    return matches.isNotEmpty ? matches.first.name : '';
  }

  void _submit() {
    final tasks = _taskControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    
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
