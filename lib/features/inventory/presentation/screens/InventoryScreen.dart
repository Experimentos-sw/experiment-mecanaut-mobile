import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppBottomSheet.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/EmptyStateView.dart';
import 'package:mecanaut_mobile/core/widgets/EntityCard.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/FilterChipGroup.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';
import 'package:mecanaut_mobile/features/calendar/data/models/calendar_event_item.dart';
import 'package:mecanaut_mobile/features/calendar/data/services/CalendarService.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/inventory_part_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';
import 'package:mecanaut_mobile/features/inventory/data/services/InventoryPartsService.dart';
import 'package:mecanaut_mobile/features/inventory/presentation/widgets/InventoryPartModal.dart';
import 'package:mecanaut_mobile/features/work_orders/data/services/WorkOrdersService.dart';

enum StockFilter { all, low }

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  late final InventoryPartsService _service;
  bool _loading = true;
  String? _error;
  List<PlantItem> _plants = <PlantItem>[];
  int? _selectedPlantId;
  List<InventoryPartItem> _parts = <InventoryPartItem>[];
  StockFilter _stockFilter = StockFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _service = InventoryPartsService(dio);
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
      List<InventoryPartItem> parts = <InventoryPartItem>[];
      if (selected != null) {
        parts = await _service.getParts(selected);
      }
      setState(() {
        _plants = plants;
        _selectedPlantId = selected;
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
      title: 'Gestion de Repuestos',
      currentRoute: '/inventario-repuestos',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Cargando repuestos...');
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    final list = _parts.where((p) {
      final matchQuery = p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.code.toLowerCase().contains(_query.toLowerCase());
      final matchFilter = _stockFilter == StockFilter.low ? p.isLowStock : true;
      return matchQuery && matchFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Inventario > Repuestos', style: TextStyle(color: Color(0xFF5B62B3))),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showFilters,
                icon: const Icon(Icons.filter_list),
                label: const Text('Filtro'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedPlantId == null ? null : _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Repuesto'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_plants.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: _selectedPlantId,
            decoration: const InputDecoration(labelText: 'Planta'),
            items: _plants
                .map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (int? value) async {
              if (value == null) return;
              setState(() => _selectedPlantId = value);
              await _reloadParts();
            },
          ),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? const EmptyStateView(
                  title: 'Sin repuestos',
                  message: 'No hay repuestos para esta planta o filtro.',
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _partCard(list[index]),
                ),
        ),
      ],
    );
  }

  Widget _partCard(InventoryPartItem part) {
    return EntityCard(
      leadingStripeColor: const Color(0xFF2A67B6),
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFF1F56A0), borderRadius: BorderRadius.circular(999)),
        child: Text(part.code, style: const TextStyle(color: Colors.white)),
      ),
      title: part.name,
      trailing: IconButton(
        onPressed: () => _showPartOptions(part),
        icon: const Icon(Icons.info_outline, color: Color(0xFF5B62B3)),
      ),
      body: Column(
        children: <Widget>[
          const Divider(),
          Row(
            children: <Widget>[
              Expanded(child: _metric('STOCK ACTUAL', '${part.currentStock}')),
              Expanded(child: _metric('STOCK MINIMO', '${part.minStock}')),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Precio unitario: S/ ${part.unitPrice.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(color: Color(0xFFB7BAC0), fontWeight: FontWeight.w700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 30 / 2,
            fontWeight: FontWeight.w700,
            color: _stockFilter == StockFilter.low ? const Color(0xFFD7465E) : const Color(0xFF1F56A0),
          ),
        ),
      ],
    );
  }

  Future<void> _reloadParts() async {
    if (_selectedPlantId == null) return;
    setState(() => _loading = true);
    try {
      final parts = await _service.getParts(_selectedPlantId!);
      setState(() {
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

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return AppBottomSheet(
          title: 'Filtros',
          onClose: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilterChipGroup<StockFilter>(
              selected: _stockFilter,
              items: <FilterChipItem<StockFilter>>[
                FilterChipItem(value: StockFilter.all, label: 'Todos'),
                FilterChipItem(value: StockFilter.low, label: 'Stock bajo'),
              ],
              onSelected: (value) {
                setState(() => _stockFilter = value);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreate() async {
    final result = await showModalBottomSheet<InventoryPartModalResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        child: InventoryPartModal(plantId: _selectedPlantId!),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
    if (result == null) return;
    try {
      await _service.create(result.toCreate());
      await _reloadParts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repuesto creado.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showPartOptions(InventoryPartItem part) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return AppBottomSheet(
          title: part.name,
          onClose: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(part.description.isEmpty ? 'Sin descripcion' : part.description),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final result = await showModalBottomSheet<InventoryPartModalResult>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AppBottomSheet(
                        child: InventoryPartModal(plantId: _selectedPlantId!, initial: part),
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    );
                    if (result == null) return;
                    try {
                      await _service.update(part.id, result.toUpdate());
                      await _reloadParts();
                    } on ApiException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                  child: const Text('Editar'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await _service.delete(part.id);
                      await _reloadParts();
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class WeeklyCalendarScreen extends StatelessWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CalendarScreen(mode: CalendarMode.weekly);
  }
}

class MonthlyCalendarScreen extends StatelessWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CalendarScreen(mode: CalendarMode.monthly);
  }
}

enum CalendarMode { weekly, monthly }

class _CalendarScreen extends ConsumerStatefulWidget {
  const _CalendarScreen({required this.mode});

  final CalendarMode mode;

  @override
  ConsumerState<_CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<_CalendarScreen> {
  late final CalendarService _calendarService;
  late final ProductionLinesService _linesService;

  bool _loading = true;
  String? _error;
  List<ProductionLineItem> _lines = <ProductionLineItem>[];
  int? _selectedLineId;
  DateTime _anchor = DateTime.now();
  List<CalendarEventItem> _events = <CalendarEventItem>[];

  @override
  void initState() {
    super.initState();
    final dio = ref.read(apiDioProvider);
    _calendarService = CalendarService(dio, WorkOrdersService(dio));
    _linesService = ProductionLinesService(dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lines = await _linesService.getProductionLines();
      int? selected = _selectedLineId;
      if (selected == null && lines.isNotEmpty) selected = lines.first.id;
      List<CalendarEventItem> events = <CalendarEventItem>[];
      if (selected != null) {
        events = await _calendarService.loadEventsByProductionLine(selected);
      }
      setState(() {
        _lines = lines;
        _selectedLineId = selected;
        _events = events;
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
    final route = widget.mode == CalendarMode.weekly ? '/calendario-semanal' : '/calendario-mensual';
    final title = widget.mode == CalendarMode.weekly ? 'Calendario Semanal' : 'Calendario Mensual';
    return AppScaffold(title: title, currentRoute: route, child: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Cargando calendario...');
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);
    if (_selectedLineId == null) {
      return const EmptyStateView(title: 'Selecciona una linea', message: 'No hay lineas disponibles.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SegmentedButton<CalendarMode>(
                segments: const <ButtonSegment<CalendarMode>>[
                  ButtonSegment(value: CalendarMode.monthly, label: Text('Mensual')),
                  ButtonSegment(value: CalendarMode.weekly, label: Text('Semanal')),
                ],
                selected: <CalendarMode>{widget.mode},
                onSelectionChanged: (selection) {
                  final selected = selection.first;
                  if (selected == widget.mode) return;
                  if (selected == CalendarMode.weekly) {
                    context.go('/calendario-semanal');
                  } else {
                    context.go('/calendario-mensual');
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 140,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Filtro'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: _selectedLineId,
          decoration: const InputDecoration(labelText: 'Linea de produccion'),
          items: _lines.map((e) => DropdownMenuItem(value: e.id, child: Text(e.display))).toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() => _selectedLineId = value);
            await _load();
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            IconButton(onPressed: () => setState(() => _anchor = _stepPeriod(-1)), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Text(DateFormat.MMMM('es').format(_anchor), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F56A0), fontSize: 20)),
                    if (widget.mode == CalendarMode.weekly)
                      Text('${DateFormat('dd/MM/yyyy').format(_weekStart(_anchor))} - ${DateFormat('dd/MM/yyyy').format(_weekStart(_anchor).add(const Duration(days: 6)))}'),
                    if (widget.mode == CalendarMode.monthly) Text('${_anchor.year}'),
                  ],
                ),
              ),
            ),
            IconButton(onPressed: () => setState(() => _anchor = _stepPeriod(1)), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: widget.mode == CalendarMode.weekly ? _weeklyView() : _monthlyView(),
        ),
      ],
    );
  }

  Widget _weeklyView() {
    final start = _weekStart(_anchor);
    final days = List<DateTime>.generate(7, (i) => start.add(Duration(days: i)));
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: days.map((d) {
              final events = _eventsForDay(d);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 1),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF0CBD4))),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(DateFormat.E('es').format(d), style: const TextStyle(color: Color(0xFF5B62B3), fontWeight: FontWeight.w700)),
                      ),
                      ...events.take(3).map((e) => _eventPill(e)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        _legend(),
      ],
    );
  }

  Widget _monthlyView() {
    final first = DateTime(_anchor.year, _anchor.month, 1);
    final firstWeekday = first.weekday % 7; // dom=0
    final daysInMonth = DateTime(_anchor.year, _anchor.month + 1, 0).day;
    final total = firstWeekday + daysInMonth;
    final rows = (total / 7).ceil();

    return Column(
      children: <Widget>[
        Row(
          children: const <Widget>[
            Expanded(child: Center(child: Text('DOM', style: TextStyle(color: Color(0xFF74A5E8))))),
            Expanded(child: Center(child: Text('LUN', style: TextStyle(color: Color(0xFF74A5E8))))),
            Expanded(child: Center(child: Text('MAR', style: TextStyle(color: Color(0xFF74A5E8))))),
            Expanded(child: Center(child: Text('MIE', style: TextStyle(color: Color(0xFF74A5E8))))),
            Expanded(child: Center(child: Text('JUE', style: TextStyle(color: Color(0xFF74A5E8))))),
            Expanded(child: Center(child: Text('VIE', style: TextStyle(color: Color(0xFF74A5E8))))),
            Expanded(child: Center(child: Text('SAB', style: TextStyle(color: Color(0xFF74A5E8))))),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: rows * 7,
            itemBuilder: (_, i) {
              final day = i - firstWeekday + 1;
              if (day < 1 || day > daysInMonth) {
                return Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEDEEF1))));
              }
              final date = DateTime(_anchor.year, _anchor.month, day);
              final events = _eventsForDay(date);
              return GestureDetector(
                onTap: () => _showDayDetails(date, events),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEDEEF1))),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('$day', style: const TextStyle(color: Color(0xFF5C92E8))),
                        const Spacer(),
                        if (events.isNotEmpty)
                          Row(
                            children: events.take(3).map((e) {
                              return Container(
                                margin: const EdgeInsets.only(right: 2),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: _eventColor(e), shape: BoxShape.circle),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _eventPill(CalendarEventItem event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 2, 2, 0),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(color: _eventColor(event), borderRadius: BorderRadius.circular(8)),
        child: Text(
          event.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        Icon(Icons.calendar_today, color: Color(0xFF74A5E8), size: 14),
        SizedBox(width: 4),
        Text('Plan de mantenimiento'),
        SizedBox(width: 14),
        Icon(Icons.build_circle_outlined, color: Color(0xFF5B62B3), size: 14),
        SizedBox(width: 4),
        Text('Orden de trabajo'),
      ],
    );
  }

  void _showDayDetails(DateTime day, List<CalendarEventItem> events) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: 'Detalles de la actividad',
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: events.isEmpty
              ? const EmptyStateView(title: 'Sin eventos', message: 'No hay actividades para este dia.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: events.map((e) => _detailTile(e)).toList(),
                ),
        ),
      ),
    );
  }

  void _showEventDetails(CalendarEventItem event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: 'Detalles de la actividad',
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _detailTile(event),
        ),
      ),
    );
  }

  Widget _detailTile(CalendarEventItem e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(e.title, style: const TextStyle(color: Color(0xFF1F56A0), fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 6),
          Text('Fecha: ${DateFormat('dd/MM/yyyy').format(e.date)}'),
          Text('Hora: ${e.timeLabel ?? '--'}'),
          Text('Estado: ${e.status}'),
          Text('Tipo: ${e.type}'),
          Text('Linea: L-${e.productionLineId}'),
          if (e.notes != null && e.notes!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text('Anotaciones: ${e.notes!}'),
          ],
        ],
      ),
    );
  }

  List<CalendarEventItem> _eventsForDay(DateTime day) {
    return _events.where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList();
  }

  Color _eventColor(CalendarEventItem e) {
    switch (e.source) {
      case CalendarEventSource.maintenancePlan:
        return const Color(0xFF74A5E8);
      case CalendarEventSource.workOrder:
        return const Color(0xFF5B62B3);
      case CalendarEventSource.executedWorkOrder:
        return const Color(0xFF52A770);
    }
  }

  DateTime _weekStart(DateTime date) {
    final weekday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday));
  }

  DateTime _stepPeriod(int direction) {
    if (widget.mode == CalendarMode.weekly) {
      return _anchor.add(Duration(days: 7 * direction));
    }
    return DateTime(_anchor.year, _anchor.month + direction, _anchor.day);
  }
}
