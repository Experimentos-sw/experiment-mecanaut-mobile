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
import 'package:mecanaut_mobile/features/assets/data/services/PlantsService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/NewProductionLineModal.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/PlantSelector.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/StatusBadge.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

class ProductionLinesScreen extends ConsumerStatefulWidget {
  const ProductionLinesScreen({super.key});

  @override
  ConsumerState<ProductionLinesScreen> createState() => _ProductionLinesScreenState();
}

class _ProductionLinesScreenState extends ConsumerState<ProductionLinesScreen> {
  late final ProductionLinesService _linesService;
  late final PlantsService _plantsService;
  late final MachinesService _machinesService;

  bool _loading = true;
  String? _error;
  List<PlantItem> _plants = <PlantItem>[];
  int? _selectedPlantId;
  List<ProductionLineItem> _lines = <ProductionLineItem>[];
  final Map<int, int> _machineCountByLine = <int, int>{};
  String _query = '';

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _linesService = ProductionLinesService(dio);
    _plantsService = PlantsService(dio);
    _machinesService = MachinesService(dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await _plantsService.getPlants();
      int? selected = _selectedPlantId;
      if (selected == null && plants.isNotEmpty) selected = plants.first.id;
      final lines = await _linesService.getProductionLines(plantId: selected);
      final machineCountByLine = <int, int>{};
      if (selected != null) {
        final machines = await _machinesService.getMachinesByPlant(selected);
        for (final machine in machines) {
          if (machine.productionLineId != null) {
            machineCountByLine[machine.productionLineId!] = (machineCountByLine[machine.productionLineId!] ?? 0) + 1;
          }
        }
      }
      setState(() {
        _plants = plants;
        _selectedPlantId = selected;
        _lines = lines;
        _machineCountByLine
          ..clear()
          ..addAll(machineCountByLine);
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
      title: 'Gestion de Lineas de Produccion',
      currentRoute: '/gestion-lineas-produccion',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Cargando lineas...');
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    final filtered = _lines.where((line) {
      final q = _query.toLowerCase().trim();
      if (q.isEmpty) return true;
      return line.name.toLowerCase().contains(q) || line.code.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(hintText: 'Buscar linea...', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Filtro'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedPlantId == null ? null : _openCreateLine,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Linea'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_plants.isNotEmpty)
          PlantSelector(
            plants: _plants,
            selectedPlantId: _selectedPlantId,
            onChanged: (value) async {
              setState(() => _selectedPlantId = value);
              await _load();
            },
          ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateView(title: 'Sin lineas', message: 'No hay lineas para esta planta.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _lineCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _lineCard(ProductionLineItem line) {
    final isActive = line.isActive;
    return EntityCard(
      leadingStripeColor: isActive ? const Color(0xFF2BC866) : const Color(0xFF6FA0E8),
      badge: Text('ID: L-${line.id.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFF7E879A))),
      trailing: StatusBadge(text: isActive ? 'Activo' : 'En Pausa'),
      title: line.name,
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _pillInfo('PRIORIDAD', '${(line.capacityUnitsPerHour / 100).ceil().clamp(1, 9)}')),
              const SizedBox(width: 8),
              Expanded(child: _pillInfo('CODIGO', line.code)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.precision_manufacturing_outlined, size: 16, color: Color(0xFF5B62B3)),
              const SizedBox(width: 6),
              Text('${_machineCountByLine[line.id] ?? 0} Maquinas', style: const TextStyle(color: Color(0xFF6E7392))),
              const Spacer(),
              IconButton(
                onPressed: () => _confirmToggleLine(line),
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF5B62B3)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF6F7FB), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: Color(0xFF9CA3B5), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF252E3E), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _openCreateLine() async {
    final result = await showModalBottomSheet<NewProductionLineModalResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        child: NewProductionLineModal(plantId: _selectedPlantId!),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
    if (result == null) return;
    try {
      await _linesService.create(result.toRequest());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Linea creada correctamente.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmToggleLine(ProductionLineItem line) async {
    final isStopping = line.isActive;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isStopping ? 'Detener linea' : 'Iniciar linea'),
          content: isStopping
              ? TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Motivo de detencion'),
                )
              : const Text('Se iniciara la linea de produccion.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      if (isStopping) {
        await _linesService.stop(line.id, reason: reasonController.text.trim().isEmpty ? 'Detencion operativa' : reasonController.text.trim());
      } else {
        await _linesService.start(line.id);
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

