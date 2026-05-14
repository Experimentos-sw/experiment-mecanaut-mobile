import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/user_item.dart';
import 'package:mecanaut_mobile/features/personnel/data/services/UsersService.dart';
import 'package:mecanaut_mobile/features/work_orders/data/models/work_order_item.dart';
import 'package:mecanaut_mobile/features/work_orders/data/services/WorkOrdersService.dart';
import 'package:mecanaut_mobile/features/work_orders/presentation/widgets/NewWorkOrderModal.dart';

class WorkOrdersScreen extends ConsumerStatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  ConsumerState<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends ConsumerState<WorkOrdersScreen> {
  late final WorkOrdersService _workOrdersService;
  late final ProductionLinesService _productionLinesService;
  late final MachinesService _machinesService;
  late final UsersService _usersService;

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _query = '';

  List<WorkOrderItem> _orders = <WorkOrderItem>[];
  List<ProductionLineItem> _lines = <ProductionLineItem>[];
  List<UserItem> _technicians = <UserItem>[];
  int? _selectedLineId;
  WorkOrderItem? _selectedOrder;

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _workOrdersService = WorkOrdersService(dio);
    _productionLinesService = ProductionLinesService(dio);
    _machinesService = MachinesService(dio);
    _usersService = UsersService(dio);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lines = await _productionLinesService.getProductionLines();
      final users = await _usersService.getUsers();
      final techs = users
          .where((u) => u.roles.contains('RoleTechnical'))
          .toList();
      setState(() {
        _lines = lines;
        _technicians = techs;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Error al cargar datos de ordenes.';
      });
    }
  }

  Future<void> _loadOrdersByLine() async {
    if (_selectedLineId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _orders = <WorkOrderItem>[];
      _selectedOrder = null;
    });
    try {
      final orders = await _workOrdersService.getByProductionLine(
        _selectedLineId!,
      );
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Orden de Trabajo',
      currentRoute: '/orden-trabajo',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Cargando ordenes...');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _loadInitial);
    }

    final list = _orders
        .where((o) => o.code.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Orden de Trabajo',
          style: TextStyle(
            fontSize: 40 / 2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF252E3E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<int>(
                initialValue: _selectedLineId,
                decoration: const InputDecoration(),
                hint: const Text('Linea'),
                items: _lines
                    .map(
                      (line) => DropdownMenuItem<int>(
                        value: line.id,
                        child: Text(line.display),
                      ),
                    )
                    .toList(),
                onChanged: (int? value) async {
                  setState(() => _selectedLineId = value);
                  await _loadOrdersByLine();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openCreateModal,
            icon: const Icon(Icons.add),
            label: const Text('Nueva Orden de Trabajo'),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedLineId == null)
          const Expanded(
            child: Center(
              child: Text(
                'Selecciona una linea de produccion para ver ordenes.',
              ),
            ),
          )
        else if (list.isEmpty)
          const Expanded(
            child: Center(child: Text('No hay ordenes para esta linea.')),
          )
        else
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final order = list[index];
                return _orderCard(order);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: list.length,
            ),
          ),
        if (_selectedOrder != null) _orderDetailBottom(_selectedOrder!),
      ],
    );
  }

  Widget _orderCard(WorkOrderItem order) {
    final date = order.date == null
        ? '--/--/----'
        : DateFormat('dd/MM/yyyy').format(order.date!);
    final typeColor = order.type.toLowerCase().contains('prevent')
        ? const Color(0xFF74A5E8)
        : const Color(0xFF6E6CD1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E8EB)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.type,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFFB8BAC0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.code,
            style: const TextStyle(
              fontSize: 34 / 2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF252E3E),
            ),
          ),
          const Divider(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: order.technicianIds.isEmpty ? null : () {},
                  child: Text(
                    order.technicianIds.isEmpty
                        ? 'Tecnicos Asignados'
                        : 'Asignar Tecnicos',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () => setState(() => _selectedOrder = order),
                icon: const Icon(Icons.info, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderDetailBottom(WorkOrderItem order) {
    final date = order.date == null
        ? '--/--/----'
        : DateFormat('dd/MM/yyyy').format(order.date!);
    final techs = _technicians
        .where((u) => order.technicianIds.contains(u.id))
        .toList();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E2E4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'CODIGO DE ORDEN',
                  style: TextStyle(
                    color: Color(0xFFB7BAC0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedOrder = null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            order.code,
            style: const TextStyle(
              fontSize: 42 / 2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F56A0),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF8F8FA),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: <Widget>[
                _metaRow('Dia', date),
                _metaRow('Tipo', order.type),
                _metaRow('Linea de Produccion', 'L-${order.productionLineId}'),
                _metaRow('Estado', order.status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'TECNICOS ASOCIADOS',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF252E3E),
            ),
          ),
          const Divider(),
          if (techs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('No hay tecnicos asignados.'),
            )
          else
            ...techs.map(
              (t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: const Color(0xFF5863B4),
                      child: Text(
                        t.initials,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t.fullName.isNotEmpty ? t.fullName : t.username,
                      style: const TextStyle(
                        color: Color(0xFF2A52B0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$k:',
              style: const TextStyle(
                color: Color(0xFFB2B4BA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            v,
            style: const TextStyle(
              color: Color(0xFF252E3E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateModal() async {
    final result = await showDialog<NewWorkOrderResult>(
      context: context,
      builder: (_) => NewWorkOrderModal(
        productionLines: _lines,
        technicians: _technicians,
        loadMachines: (lineId) =>
            _machinesService.getMachinesByProductionLine(lineId),
        isSubmitting: _submitting,
      ),
    );

    if (result == null) return;

    setState(() => _submitting = true);
    try {
      await _workOrdersService.create(result.request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden creada correctamente.')),
      );
      await _loadOrdersByLine();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
