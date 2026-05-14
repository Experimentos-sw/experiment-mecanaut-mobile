import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/user_item.dart';
import 'package:mecanaut_mobile/features/work_orders/data/models/create_work_order_request.dart';

class NewWorkOrderResult {
  NewWorkOrderResult(this.request);

  final CreateWorkOrderRequest request;
}

class NewWorkOrderModal extends StatefulWidget {
  const NewWorkOrderModal({
    super.key,
    required this.productionLines,
    required this.technicians,
    required this.loadMachines,
    this.isSubmitting = false,
  });

  final List<ProductionLineItem> productionLines;
  final List<UserItem> technicians;
  final Future<List<MachineItem>> Function(int lineId) loadMachines;
  final bool isSubmitting;

  @override
  State<NewWorkOrderModal> createState() => _NewWorkOrderModalState();
}

class _NewWorkOrderModalState extends State<NewWorkOrderModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController(
    text: 'OT-${DateTime.now().year}-01',
  );
  final _dateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final _taskController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int? _selectedLineId;
  List<MachineItem> _availableMachines = <MachineItem>[];
  final Set<int> _selectedMachineIds = <int>{};
  final Set<int> _selectedTechnicianIds = <int>{};
  final List<String> _tasks = <String>[];
  bool _loadingMachines = false;

  @override
  void dispose() {
    _codeController.dispose();
    _dateController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Orden de Trabajo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F56A0),
                  ),
                ),
                const SizedBox(height: 16),
                _label('Codigo'),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(hintText: 'OT-2025-01'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),
                const SizedBox(height: 14),
                _label('Fecha'),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),
                _label('Linea de Produccion'),
                DropdownButtonFormField<int>(
                  initialValue: _selectedLineId,
                  items: widget.productionLines
                      .map(
                        (line) => DropdownMenuItem<int>(
                          value: line.id,
                          child: Text(line.display),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) async {
                    setState(() {
                      _selectedLineId = value;
                      _availableMachines = <MachineItem>[];
                      _selectedMachineIds.clear();
                    });
                    if (value != null) {
                      await _loadMachines(value);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona una linea' : null,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE4E4E6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6469BE),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Tecnico',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'maquinaria',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (_selectedTechnicianIds.isEmpty)
                              const Text('Sin tecnicos seleccionados')
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.technicians
                                    .where(
                                      (e) =>
                                          _selectedTechnicianIds.contains(e.id),
                                    )
                                    .map(
                                      (tech) => Chip(
                                        label: Text(
                                          tech.fullName.isEmpty
                                              ? tech.username
                                              : tech.fullName,
                                        ),
                                        onDeleted: () {
                                          setState(
                                            () => _selectedTechnicianIds.remove(
                                              tech.id,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: 10),
                            if (_selectedMachineIds.isEmpty)
                              const Text('Sin maquinarias seleccionadas')
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableMachines
                                    .where(
                                      (e) => _selectedMachineIds.contains(e.id),
                                    )
                                    .map(
                                      (machine) => Chip(
                                        label: Text(machine.display),
                                        onDeleted: () {
                                          setState(
                                            () => _selectedMachineIds.remove(
                                              machine.id,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _showTechnicianPicker,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Tecnico'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _selectedLineId == null
                      ? null
                      : _showMachinePicker,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    _loadingMachines
                        ? 'Cargando maquinarias...'
                        : 'Agregar Maquinaria',
                  ),
                ),
                const SizedBox(height: 14),
                _label('Tareas'),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          hintText: 'Ingresar tarea',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addTask,
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF1F56A0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tasks
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          onDeleted: () => setState(() => _tasks.remove(t)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.isSubmitting ? null : _submit,
                    child: widget.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE595AA),
                      side: const BorderSide(color: Color(0xFFE595AA)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  Future<void> _loadMachines(int lineId) async {
    setState(() => _loadingMachines = true);
    final machines = await widget.loadMachines(lineId);
    if (mounted) {
      setState(() {
        _availableMachines = machines;
        _loadingMachines = false;
      });
    }
  }

  void _showTechnicianPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListView(
            children: widget.technicians.map((tech) {
              final selected = _selectedTechnicianIds.contains(tech.id);
              return CheckboxListTile(
                value: selected,
                title: Text(
                  tech.fullName.isEmpty ? tech.username : tech.fullName,
                ),
                subtitle: Text(tech.email),
                onChanged: (bool? value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedTechnicianIds.add(tech.id);
                    } else {
                      _selectedTechnicianIds.remove(tech.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showMachinePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: _availableMachines.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No hay maquinarias para esta linea.'),
                  ),
                )
              : ListView(
                  children: _availableMachines.map((machine) {
                    final selected = _selectedMachineIds.contains(machine.id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(machine.display),
                      subtitle: Text(machine.name),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedMachineIds.add(machine.id);
                          } else {
                            _selectedMachineIds.remove(machine.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  void _addTask() {
    final value = _taskController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _tasks.add(value);
      _taskController.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una tarea.')),
      );
      return;
    }

    final request = CreateWorkOrderRequest(
      code: _codeController.text.trim(),
      date: _selectedDate,
      productionLineId: _selectedLineId!,
      type: 'Corrective',
      machineIds: _selectedMachineIds.toList(),
      tasks: _tasks,
      technicianIds: _selectedTechnicianIds.map((e) => e as int?).toList(),
    );
    Navigator.of(context).pop(NewWorkOrderResult(request));
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1F56A0),
        fontSize: 30 / 2,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
