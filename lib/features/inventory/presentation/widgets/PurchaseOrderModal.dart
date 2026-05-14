import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/inventory_part_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/purchase_order_item.dart';

class PurchaseOrderModalResult {
  PurchaseOrderModalResult({
    required this.orderNumber,
    required this.inventoryPartId,
    required this.quantity,
    required this.totalPrice,
    required this.deliveryDate,
    required this.plantId,
  });

  final String orderNumber;
  final int inventoryPartId;
  final int quantity;
  final double totalPrice;
  final DateTime deliveryDate;
  final int plantId;

  PurchaseOrderCreateRequest toCreate() => PurchaseOrderCreateRequest(
        orderNumber: orderNumber,
        inventoryPartId: inventoryPartId,
        quantity: quantity,
        totalPrice: totalPrice,
        plantId: plantId,
        deliveryDate: deliveryDate,
      );
}

class PurchaseOrderModal extends StatefulWidget {
  const PurchaseOrderModal({
    super.key,
    required this.plantId,
    required this.parts,
  });

  final int plantId;
  final List<InventoryPartItem> parts;

  @override
  State<PurchaseOrderModal> createState() => _PurchaseOrderModalState();
}

class _PurchaseOrderModalState extends State<PurchaseOrderModal> {
  final _formKey = GlobalKey<FormState>();
  final _orderNumberController = TextEditingController(
    text: 'OC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
  );
  final _quantityController = TextEditingController(text: '1');
  final _totalPriceController = TextEditingController(text: '0');
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  int? _partId;

  @override
  void initState() {
    super.initState();
    if (widget.parts.isNotEmpty) {
      _partId = widget.parts.first.id;
      _totalPriceController.text = widget.parts.first.unitPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _quantityController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Nueva Orden de Compra',
                  style: TextStyle(color: Color(0xFF1F56A0), fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('Numero de orden'),
                TextFormField(
                  controller: _orderNumberController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                const Text('Repuesto'),
                DropdownButtonFormField<int>(
                  initialValue: _partId,
                  items: widget.parts
                      .map((p) => DropdownMenuItem<int>(value: p.id, child: Text('${p.code} - ${p.name}')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _partId = value);
                      final selected = widget.parts.firstWhere((e) => e.id == value);
                      _totalPriceController.text = selected.unitPrice.toStringAsFixed(2);
                    }
                  },
                  validator: (v) => v == null ? 'Selecciona repuesto' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Cantidad'),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Invalido';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Precio total'),
                          TextFormField(
                            controller: _totalPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(prefixText: 'S/ '),
                            validator: (v) {
                              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                              if (n == null || n < 0) return 'Invalido';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Fecha de entrega'),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_deliveryDate)),
                  decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2050),
    );
    if (date != null) {
      setState(() => _deliveryDate = date);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      PurchaseOrderModalResult(
        orderNumber: _orderNumberController.text.trim(),
        inventoryPartId: _partId!,
        quantity: int.parse(_quantityController.text),
        totalPrice: double.parse(_totalPriceController.text.replaceAll(',', '.')),
        deliveryDate: _deliveryDate,
        plantId: widget.plantId,
      ),
    );
  }
}
