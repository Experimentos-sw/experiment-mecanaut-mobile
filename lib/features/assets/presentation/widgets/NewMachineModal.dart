import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MetricDefinitionsService.dart';

class NewMachineModalResult {
  NewMachineModalResult({
    required this.serialNumber,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.type,
    required this.powerConsumption,
    required this.plantId,
    required this.metrics,
  });

  final String serialNumber;
  final String name;
  final String manufacturer;
  final String model;
  final String type;
  final double powerConsumption;
  final int plantId;
  final List<MachineMetricCreateItem> metrics;

  RegisterMachineRequest toRequest() {
    return RegisterMachineRequest(
      serialNumber: serialNumber,
      name: name,
      manufacturer: manufacturer,
      plantId: plantId,
      model: model,
      type: type,
      powerConsumption: powerConsumption,
      metrics: metrics,
    );
  }
}

class NewMachineModal extends StatefulWidget {
  const NewMachineModal({
    super.key,
    required this.plantId,
    required this.metricDefinitions,
  });

  final int plantId;
  final List<MetricDefinitionItem> metricDefinitions;

  @override
  State<NewMachineModal> createState() => _NewMachineModalState();
}

class _NewMachineModalState extends State<NewMachineModal> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _typeController = TextEditingController(text: 'Industrial');
  final _powerController = TextEditingController();
  DateTime _lastMaintenance = DateTime.now();
  final List<_MetricDraft> _metricDrafts = <_MetricDraft>[];

  @override
  void initState() {
    super.initState();
    if (widget.metricDefinitions.isNotEmpty) {
      _metricDrafts.add(_MetricDraft(definition: widget.metricDefinitions.first));
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _serialController.dispose();
    _nameController.dispose();
    _manufacturerController.dispose();
    _typeController.dispose();
    _powerController.dispose();
    for (final draft in _metricDrafts) {
      draft.valueController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Nueva Maquinaria',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F56A0), fontSize: 34 / 2),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _label('Modelo'),
                    TextFormField(
                      controller: _modelController,
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    _label('Nombre'),
                    TextFormField(
                      controller: _nameController,
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    _label('Numero de serie'),
                    TextFormField(
                      controller: _serialController,
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    _label('Fabricante'),
                    TextFormField(
                      controller: _manufacturerController,
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    _label('Tipo'),
                    TextFormField(
                      controller: _typeController,
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    _label('Ultimo mantenimiento'),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_lastMaintenance)),
                      onTap: _pickDate,
                      decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month_outlined)),
                    ),
                    const SizedBox(height: 10),
                    _label('Potencia'),
                    TextFormField(
                      controller: _powerController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(suffixText: 'kW'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Potencia invalida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Metricas iniciales', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._metricDrafts.map(_metricRow),
                    if (widget.metricDefinitions.isNotEmpty)
                      TextButton.icon(
                        onPressed: _addMetric,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar metrica'),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD7465E),
                          side: const BorderSide(color: Color(0xFFD7465E)),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(_MetricDraft draft) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: draft.definition.id,
              items: widget.metricDefinitions
                  .map((m) => DropdownMenuItem<int>(value: m.id, child: Text('${m.name} (${m.unit})')))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final def = widget.metricDefinitions.firstWhere((m) => m.id == value);
                setState(() => draft.definition = def);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: draft.valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Valor'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return double.tryParse(v) == null ? 'Invalido' : null;
              },
            ),
          ),
          IconButton(
            onPressed: _metricDrafts.length <= 1 ? null : () => _removeMetric(draft),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: Color(0xFF1F56A0))),
      );

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    return null;
  }

  void _addMetric() {
    setState(() {
      _metricDrafts.add(_MetricDraft(definition: widget.metricDefinitions.first));
    });
  }

  void _removeMetric(_MetricDraft draft) {
    setState(() {
      draft.valueController.dispose();
      _metricDrafts.remove(draft);
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _lastMaintenance,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (selected != null) {
      setState(() => _lastMaintenance = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final metrics = _metricDrafts
        .where((m) => m.valueController.text.trim().isNotEmpty)
        .map((m) => MachineMetricCreateItem(
              metricId: m.definition.id,
              value: double.parse(m.valueController.text),
              measuredAt: _lastMaintenance,
            ))
        .toList();

    Navigator.of(context).pop(
      NewMachineModalResult(
        serialNumber: _serialController.text.trim(),
        name: _nameController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        model: _modelController.text.trim(),
        type: _typeController.text.trim(),
        powerConsumption: double.parse(_powerController.text),
        plantId: widget.plantId,
        metrics: metrics,
      ),
    );
  }
}

class _MetricDraft {
  _MetricDraft({required this.definition});

  MetricDefinitionItem definition;
  final TextEditingController valueController = TextEditingController();
}

