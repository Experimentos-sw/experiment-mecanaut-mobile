import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppBottomSheet.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/EmptyStateView.dart';
import 'package:mecanaut_mobile/core/widgets/EntityCard.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/inventory_part_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/purchase_order_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/services/InventoryPartsService.dart';
import 'package:mecanaut_mobile/features/inventory/data/services/PurchaseOrdersService.dart';
import 'package:mecanaut_mobile/features/inventory/presentation/widgets/PurchaseOrderModal.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  late final PurchaseOrdersService _service;
  late final InventoryPartsService _partsService;

  bool _loading = true;
  String? _error;
  List<PlantItem> _plants = <PlantItem>[];
  int? _selectedPlantId;
  List<InventoryPartItem> _parts = <InventoryPartItem>[];
  List<PurchaseOrderItem> _orders = <PurchaseOrderItem>[];
  String _query = '';

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _service = PurchaseOrdersService(dio);
    _partsService = InventoryPartsService(dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await _service.getPlants();
      int? selected = _selectedPlantId;
      if (selected == null && plants.isNotEmpty) selected = plants.first.id;
      List<PurchaseOrderItem> orders = <PurchaseOrderItem>[];
      List<InventoryPartItem> parts = <InventoryPartItem>[];
      if (selected != null) {
        orders = await _service.getPurchaseOrders(selected);
        parts = await _partsService.getParts(selected);
      }
      setState(() {
        _plants = plants;
        _selectedPlantId = selected;
        _orders = orders;
        _parts = parts;
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
      title: 'Orden de Compra',
      currentRoute: '/orden-compra',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Cargando ordenes de compra...');
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    final list = _orders.where((o) => o.orderNumber.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: <Widget>[
        _buildToolbar(),
        const SizedBox(height: 10),
        if (_plants.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: _selectedPlantId,
            decoration: const InputDecoration(labelText: 'Planta'),
            items: _plants.map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name))).toList(),
            onChanged: (int? value) async {
              if (value == null) return;
              setState(() => _selectedPlantId = value);
              await _load();
            },
          ),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? const EmptyStateView(title: 'Sin ordenes de compra')
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _orderCard(list[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final searchField = TextField(
      decoration: const InputDecoration(
        hintText: 'Buscar orden...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (v) => setState(() => _query = v),
    );

    final filterButton = OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.filter_alt_outlined),
      label: const Text('Filtro'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
    );

    final createButton = ElevatedButton.icon(
      onPressed: _selectedPlantId == null ? null : _openCreate,
      icon: const Icon(Icons.add),
      label: const Text('Nueva orden de compra'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 52)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              searchField,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: filterButton),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: createButton),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: searchField),
            const SizedBox(width: 10),
            SizedBox(width: 150, child: filterButton),
            const SizedBox(width: 10),
            SizedBox(width: 230, child: createButton),
          ],
        );
      },
    );
  }

  Widget _orderCard(PurchaseOrderItem order) {
    final pending = order.status.toLowerCase().contains('pending') || order.status.toLowerCase().contains('created');
    final badgeColor = pending ? const Color(0xFFF3E7A7) : const Color(0xFFD7F1DD);
    final badgeText = pending ? 'Pendiente' : 'Recibida';
    final dateLabel = order.deliveryDate ?? order.orderDate;
    final part = _parts.where((p) => p.id == order.inventoryPartId).cast<InventoryPartItem?>().firstOrNull;

    return EntityCard(
      badge: Text('ID-OC', style: TextStyle(color: Colors.grey.shade600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
        child: Text(badgeText, style: TextStyle(color: pending ? const Color(0xFF9A7C12) : const Color(0xFF3D8B5A))),
      ),
      title: order.orderNumber,
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF6F6F9), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: <Widget>[
                Expanded(child: _metric('Cantidad', '${order.quantity}')),
                Expanded(child: _metric('Precio Total', 'S/ ${order.totalPrice.toStringAsFixed(2)}')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('📅 ${pending ? 'Solicitada' : 'Recibida'}: ${dateLabel == null ? '--/--/----' : DateFormat('dd/MM/yyyy').format(dateLabel)}'),
              const Spacer(),
              TextButton(onPressed: () => _showDetails(order, part), child: const Text('Ver detalles')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(color: Color(0xFF7E879A))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF252E3E))),
      ],
    );
  }

  Future<void> _openCreate() async {
    final result = await showModalBottomSheet<PurchaseOrderModalResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        child: PurchaseOrderModal(plantId: _selectedPlantId!, parts: _parts),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
    if (result == null) return;

    try {
      await _service.create(result.toCreate());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orden de compra creada.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showDetails(PurchaseOrderItem order, InventoryPartItem? part) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: 'Detalle de orden',
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Orden: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('Repuesto: ${part?.name ?? order.inventoryPartId}'),
              Text('Cantidad: ${order.quantity}'),
              Text('Precio total: S/ ${order.totalPrice.toStringAsFixed(2)}'),
              Text('Estado: ${order.status}'),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        try {
                          await _service.complete(order.id);
                          await _load();
                        } on ApiException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                          }
                        }
                      },
                      child: const Text('Completar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        try {
                          await _service.delete(order.id);
                          await _load();
                        } on ApiException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD7465E),
                        side: const BorderSide(color: Color(0xFFD7465E)),
                      ),
                      child: const Text('Eliminar'),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
