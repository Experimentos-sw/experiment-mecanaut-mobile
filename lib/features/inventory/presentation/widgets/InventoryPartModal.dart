import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/inventory_part_item.dart';

class InventoryPartModalResult {
  InventoryPartModalResult({
    required this.code,
    required this.name,
    required this.description,
    required this.currentStock,
    required this.minStock,
    required this.unitPrice,
    required this.plantId,
    this.isEdit = false,
  });

  final String code;
  final String name;
  final String description;
  final int currentStock;
  final int minStock;
  final double unitPrice;
  final int plantId;
  final bool isEdit;

  InventoryPartCreateRequest toCreate() {
    return InventoryPartCreateRequest(
      code: code,
      name: name,
      description: description,
      currentStock: currentStock,
      minStock: minStock,
      unitPrice: unitPrice,
      plantId: plantId,
    );
  }

  InventoryPartUpdateRequest toUpdate() {
    return InventoryPartUpdateRequest(
      description: description,
      currentStock: currentStock,
      minStock: minStock,
      unitPrice: unitPrice,
    );
  }
}

class InventoryPartModal extends StatefulWidget {
  const InventoryPartModal({
    super.key,
    required this.plantId,
    this.initial,
  });

  final int plantId;
  final InventoryPartItem? initial;

  bool get isEdit => initial != null;

  @override
  State<InventoryPartModal> createState() => _InventoryPartModalState();
}

class _InventoryPartModalState extends State<InventoryPartModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _unitPriceController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initial?.code ?? '');
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initial?.description ?? '');
    _currentStockController = TextEditingController(text: '${widget.initial?.currentStock ?? 0}');
    _minStockController = TextEditingController(text: '${widget.initial?.minStock ?? 0}');
    _unitPriceController = TextEditingController(text: '${widget.initial?.unitPrice ?? 0}');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _unitPriceController.dispose();
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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: <Widget>[
                  Text(
                    widget.isEdit ? 'Editar Repuesto' : 'Nuevo Repuesto',
                    style: const TextStyle(
                      color: Color(0xFF1F56A0),
                      fontWeight: FontWeight.w700,
                      fontSize: 36 / 2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _label('Codigo'),
                    TextFormField(
                      controller: _codeController,
                      enabled: !widget.isEdit,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Codigo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    _label('Nombre'),
                    TextFormField(
                      controller: _nameController,
                      enabled: !widget.isEdit,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    _label('Descripcion'),
                    TextFormField(controller: _descriptionController, maxLines: 3),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _label('Stock Actual'),
                              TextFormField(
                                controller: _currentStockController,
                                keyboardType: TextInputType.number,
                                validator: _nonNegativeIntValidator,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _label('Stock Minimo'),
                              TextFormField(
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                validator: _nonNegativeIntValidator,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _label('Precio unitario'),
                    TextFormField(
                      controller: _unitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _nonNegativeDoubleValidator,
                      decoration: const InputDecoration(prefixText: 'S/ '),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE24B6C),
                              side: const BorderSide(color: Color(0xFFE24B6C)),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Guardar'),
                          ),
                        ),
                      ],
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text, style: const TextStyle(fontSize: 31 / 2, color: Color(0xFF353535))),
      );

  String? _nonNegativeIntValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) return 'Valor invalido';
    if (parsed < 0) return 'Debe ser >= 0';
    return null;
  }

  String? _nonNegativeDoubleValidator(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null) return 'Valor invalido';
    if (parsed < 0) return 'Debe ser >= 0';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = InventoryPartModalResult(
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      currentStock: int.parse(_currentStockController.text),
      minStock: int.parse(_minStockController.text),
      unitPrice: double.parse(_unitPriceController.text.replaceAll(',', '.')),
      plantId: widget.plantId,
      isEdit: widget.isEdit,
    );

    Navigator.of(context).pop(result);
  }
}
