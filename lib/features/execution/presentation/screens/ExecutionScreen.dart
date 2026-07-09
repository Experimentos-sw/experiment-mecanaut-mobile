import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';
import 'package:mecanaut_mobile/features/work_orders/data/models/work_order_item.dart';
import 'package:mecanaut_mobile/features/execution/data/services/ExecutionService.dart';
import 'package:mecanaut_mobile/features/execution/data/models/save_executed_work_order_request.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/services/ExperimentTelemetryService.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/telemetry_resource.dart';

class ExecutionScreen extends ConsumerStatefulWidget {
  const ExecutionScreen({super.key});

  @override
  ConsumerState<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  late final ExecutionService _executionService;
  late final ExperimentTelemetryService _telemetryService;

  bool _loading = true;
  String? _error;

  List<PlantItem> _plants = [];
  List<ProductionLineItem> _lines = [];
  List<WorkOrderItem> _orders = [];
  List<InventoryPartDto> _inventoryParts = [];

  int? _selectedPlantId;
  int? _selectedLineId;
  int? _selectedOrderId;

  WorkOrderItem? get _selectedOrder => 
      _selectedOrderId != null ? _orders.where((o) => o.id == _selectedOrderId).firstOrNull : null;

  // Execution state for the selected order
  List<MachineItem> _orderMachineries = [];
  List<Map<String, dynamic>> _tasks = [];
  String _observations = '';
  List<Map<String, dynamic>> _usedProducts = [];
  bool _noProductsUsed = false;
  List<String> _images = [];
  
  final ImagePicker _picker = ImagePicker();
  int? _savedExecutedOrderId;
  bool _submitting = false;

  final List<String> _defaultTasks = [
    'Drenar aceite',
    'Reemplazar filtro',
    'Rellenar aceite',
    'Prueba de funcionamiento',
    'Inspeccion visual'
  ];

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _executionService = ExecutionService(dio);
    _telemetryService = ExperimentTelemetryService(dio);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final plants = await _executionService.getPlants();
      setState(() {
        _plants = plants;
        if (plants.isNotEmpty) {
          _selectedPlantId = plants.first.id;
        }
        _loading = false;
      });
      if (_selectedPlantId != null) {
        await _loadPlantData();
      }
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Error al cargar plantas';
        _loading = false;
      });
    }
  }

  Future<void> _loadPlantData() async {
    if (_selectedPlantId == null) return;
    setState(() => _loading = true);
    try {
      _lines = await _executionService.getProductionLines(_selectedPlantId!);
      _inventoryParts = await _executionService.getInventoryParts(_selectedPlantId!);
      _selectedLineId = null;
      _selectedOrderId = null;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Error al cargar datos de planta';
        _loading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    if (_selectedLineId == null) return;
    setState(() => _loading = true);
    try {
      _orders = await _executionService.getWorkOrdersToExecute(_selectedLineId!);
      _selectedOrderId = null;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Error al cargar ordenes de trabajo';
        _loading = false;
      });
    }
  }

  Future<void> _loadOrderDetails() async {
    if (_selectedOrder == null) return;
    setState(() => _loading = true);
    try {
      _orderMachineries = await _executionService.getMachineriesByWorkOrder(_selectedOrder!);
      
      _tasks = _defaultTasks.map((t) => {'label': t, 'completed': false}).toList();
      if (_selectedOrder!.tasks.isNotEmpty) {
        _tasks = _selectedOrder!.tasks.map((t) => {'label': t, 'completed': false}).toList();
      }
      
      _observations = '';
      _usedProducts = [{'partId': null, 'quantity': 1}];
      _noProductsUsed = false;
      _images = [];
      _savedExecutedOrderId = null;

      await _tryLoadSavedProgress();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Error al cargar detalles de orden';
        _loading = false;
      });
    }
  }

  Future<void> _tryLoadSavedProgress() async {
    if (_selectedLineId == null || _selectedOrder == null) return;
    try {
      final savedList = await _executionService.getExecutedWorkOrdersByProductionLine(_selectedLineId!);
      final match = savedList.where((o) => o.code == _selectedOrder!.code).firstOrNull;
      if (match != null) {
        final fullData = await _executionService.getExecutedWorkOrder(match.id);
        
        for (var t in _tasks) {
          if (fullData.executedTasks.contains(t['label'])) {
            t['completed'] = true;
          }
        }
        
        if (fullData.usedProducts.isNotEmpty) {
          _usedProducts = fullData.usedProducts.map((p) => {
            'partId': p.productId,
            'quantity': p.quantity
          }).toList();
        }
        
        _images = List<String>.from(fullData.executionImages);
        _observations = fullData.annotations;
        _savedExecutedOrderId = fullData.id;
      }
    } catch (e) {
      // Ignoramos error al cargar progreso, es opcional
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _submitting = true);
      try {
        final url = await _executionService.uploadImage(image.path, image.name);
        setState(() {
          _images.add(url);
          _submitting = false;
        });
      } catch (e) {
        setState(() => _submitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir imagen')));
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _addProductRow() {
    setState(() => _usedProducts.add({'partId': null, 'quantity': 1}));
  }

  void _removeProductRow(int index) {
    setState(() => _usedProducts.removeAt(index));
  }

  Future<bool> _saveProgress() async {
    if (_selectedOrder == null) return false;
    setState(() => _submitting = true);
    bool success = false;
    
    try {
      final request = SaveExecutedWorkOrderRequest(
        code: _selectedOrder!.code,
        annotations: _observations,
        executionDate: DateTime.now().toIso8601String(),
        productionLineId: _selectedLineId!,
        intervenedMachineIds: _selectedOrder!.machineIds,
        assignedTechnicianIds: _selectedOrder!.technicianIds,
        executedTasks: _tasks.where((t) => t['completed'] == true).map((t) => t['label'] as String).toList(),
        usedProducts: _noProductsUsed ? [] : _usedProducts
            .where((p) => p['partId'] != null)
            .map((p) => ExecutionProductRequest(productId: p['partId'], quantity: p['quantity']))
            .toList(),
        files: _images,
        workOrderId: _selectedOrderId!,
      );
      
      await _executionService.saveExecutedWorkOrder(request);
      success = true;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Progreso guardado correctamente.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar progreso: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    return success;
  }

  Future<void> _finishOrder() async {
    if (_selectedOrder == null) return;
    
    // Validate
    bool allTasksDone = _tasks.every((t) => t['completed'] == true);
    if (!allTasksDone) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debes completar todas las tareas.')));
      return;
    }
    if (_observations.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debes agregar observaciones.')));
      return;
    }
    bool productsValid = _noProductsUsed || _usedProducts.any((p) => p['partId'] != null && p['quantity'] > 0);
    if (!productsValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agrega productos o marca "Sin productos".')));
      return;
    }
    
    if (!_noProductsUsed) {
      List<Map<String, dynamic>> shortages = [];
      for (var p in _usedProducts) {
        if (p['partId'] == null) continue;
        int partId = p['partId'];
        int required = p['quantity'];
        final part = _inventoryParts.where((ip) => ip.id == partId).firstOrNull;
        int available = part?.currentStock ?? 0;
        if (required > available) {
          shortages.add({
            'name': part?.name ?? part?.code ?? partId.toString(),
            'required': required,
            'available': available,
          });
        }
      }

      if (shortages.isNotEmpty) {
        _telemetryService.recordMetric(TelemetryResource(
          experimentName: 'US11-R',
          variant: 'Treatment',
          actionType: 'Order_Start_Inventory_Warning_Shown',
          durationMilliseconds: 0,
          isSuccess: true,
          additionalData: '{"orderId": ${_selectedOrder!.id}, "shortages": ${shortages.length}}'
        ));

        _showInventoryAlert(shortages);
        return;
      }
    }

    _telemetryService.recordMetric(TelemetryResource(
      experimentName: 'US11-R',
      variant: 'Treatment',
      actionType: 'Order_Start_Inventory_OK',
      durationMilliseconds: 0,
      isSuccess: true,
      additionalData: '{"orderId": ${_selectedOrder!.id}}'
    ));

    bool saved = await _saveProgress();
    if (!saved) return;
    
    // Simulate completing order logic
    if (mounted) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text('Validacion Exitosa'),
        content: Text('Orden finalizada exitosamente.'),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context);
            setState(() {
              _selectedOrderId = null;
            });
            _loadOrders();
          }, child: Text('Cerrar'))
        ],
      ));
    }
  }

  void _showInventoryAlert(List<Map<String, dynamic>> shortages) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Stock insuficiente', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se detectaron repuestos con cantidad insuficiente. No es posible finalizar la orden hasta resolver los faltantes.'),
            const SizedBox(height: 10),
            ...shortages.map((s) => Text('• ${s['name']}: Req ${s['required']}, Disp ${s['available']}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ejecucion',
      currentRoute: '/ejecucion',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _plants.isEmpty) return const LoadingView();
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _loadInitial);

    return Stack(
      children: [
        Column(
          children: [
            _buildSelectors(),
            const SizedBox(height: 16),
            if (_loading && _plants.isNotEmpty) 
               const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!_loading && _selectedOrder == null)
               const Expanded(child: Center(child: Text('Selecciona una orden de trabajo.'))),
            if (!_loading && _selectedOrder != null)
               Expanded(child: _buildOrderForm()),
          ],
        ),
        if (_submitting) Positioned.fill(
          child: Container(color: Colors.black26, child: Center(child: CircularProgressIndicator())),
        ),
      ],
    );
  }

  Widget _buildSelectors() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          value: _selectedPlantId,
          decoration: const InputDecoration(labelText: 'Planta'),
          items: _plants.map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name))).toList(),
          onChanged: (val) {
            setState(() => _selectedPlantId = val);
            _loadPlantData();
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedLineId,
          decoration: const InputDecoration(labelText: 'Linea de Produccion'),
          items: _lines.map<DropdownMenuItem<int>>((l) => DropdownMenuItem<int>(value: l.id, child: Text(l.name))).toList(),
          onChanged: _selectedPlantId == null ? null : (val) {
            setState(() => _selectedLineId = val);
            _loadOrders();
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedOrderId,
          decoration: const InputDecoration(labelText: 'Orden de Trabajo'),
          items: _orders.map<DropdownMenuItem<int>>((o) => DropdownMenuItem<int>(value: o.id, child: Text('${o.code} - ${o.type}'))).toList(),
          onChanged: _selectedLineId == null ? null : (val) {
            setState(() => _selectedOrderId = val);
            _loadOrderDetails();
          },
        ),
      ],
    );
  }

  Widget _buildOrderForm() {
    return SingleChildScrollView(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedOrder!.code, style: Theme.of(context).textTheme.titleLarge),
              Text('Tipo: ${_selectedOrder!.type}'),
              Text('Estado: ${_selectedOrder!.status}'),
              const Divider(height: 30),
              
              const Text('Maquinarias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (_orderMachineries.isEmpty) const Text('Ninguna asignada.'),
              ..._orderMachineries.map((m) => Text('• ${m.name} (${m.status})')),
              const Divider(height: 30),
              
              const Text('Tareas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ..._tasks.asMap().entries.map((e) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(e.value['label']),
                value: e.value['completed'],
                onChanged: (val) {
                  setState(() => _tasks[e.key]['completed'] = val);
                },
              )),
              const Divider(height: 30),
              
              const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ingresa observaciones...'),
                maxLines: 3,
                onChanged: (val) => _observations = val,
                controller: TextEditingController(text: _observations)..selection = TextSelection.collapsed(offset: _observations.length),
              ),
              const Divider(height: 30),
              
              const Text('Imagenes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.asMap().entries.map((e) => Stack(
                    children: [
                      Image.network(e.value, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey)),
                      Positioned(right: 0, top: 0, child: GestureDetector(
                        onTap: () => _removeImage(e.key),
                        child: Container(color: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 20)),
                      )),
                    ],
                  )),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  )
                ],
              ),
              const Divider(height: 30),
              
              const Text('Productos Utilizados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('No se utilizaron productos'),
                value: _noProductsUsed,
                onChanged: (val) => setState(() => _noProductsUsed = val ?? false),
              ),
              if (!_noProductsUsed) ...[
                ..._usedProducts.asMap().entries.map((e) => Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int?>(
                        value: e.value['partId'],
                        decoration: InputDecoration(labelText: 'Repuesto'),
                        items: _inventoryParts.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                        onChanged: (val) => setState(() => _usedProducts[e.key]['partId'] = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: e.value['quantity'].toString(),
                        decoration: InputDecoration(labelText: 'Cant.'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() => _usedProducts[e.key]['quantity'] = int.tryParse(val) ?? 1),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.delete), onPressed: () => _removeProductRow(e.key)),
                  ],
                )),
                TextButton.icon(
                  onPressed: _addProductRow,
                  icon: Icon(Icons.add),
                  label: Text('Agregar repuesto'),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saveProgress,
                      child: Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finishOrder,
                      child: Text('Finalizar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
