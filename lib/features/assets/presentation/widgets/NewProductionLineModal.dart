import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';

class NewProductionLineModalResult {
  NewProductionLineModalResult({
    required this.name,
    required this.code,
    required this.capacityUnitsPerHour,
    required this.plantId,
  });

  final String name;
  final String code;
  final double capacityUnitsPerHour;
  final int plantId;

  CreateProductionLineRequest toRequest() {
    return CreateProductionLineRequest(
      name: name,
      code: code,
      capacityUnitsPerHour: capacityUnitsPerHour,
      plantId: plantId,
    );
  }
}

class NewProductionLineModal extends StatefulWidget {
  const NewProductionLineModal({
    super.key,
    required this.plantId,
  });

  final int plantId;

  @override
  State<NewProductionLineModal> createState() => _NewProductionLineModalState();
}

class _NewProductionLineModalState extends State<NewProductionLineModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _capacityController = TextEditingController(text: '100');

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _capacityController.dispose();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Nueva Linea de Produccion',
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
                    const Text('Nombre'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Codigo interno'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _codeController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Codigo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Capacidad (unidades/hora)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Ingresa una capacidad valida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewProductionLineModalResult(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        capacityUnitsPerHour: double.parse(_capacityController.text),
        plantId: widget.plantId,
      ),
    );
  }
}

