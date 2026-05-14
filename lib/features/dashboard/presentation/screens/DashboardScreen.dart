import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final MachinesService _machinesService;

  bool _loading = true;
  String? _error;
  List<MachineItem> _machines = <MachineItem>[];
  DateTime _weekDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _machinesService = MachinesService(ref.read(apiDioProvider));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final machines = await _machinesService.getAllMachines();
      setState(() {
        _machines = machines;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo cargar el dashboard.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Cargando dashboard...');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _loadData);
    }

    final session = ref.watch(authSessionProvider);
    final username = session.user?.fullName?.trim().isNotEmpty == true
        ? session.user!.fullName!
        : (session.user?.username ?? 'Usuario');

    final total = _machines.isEmpty ? 1 : _machines.length;
    final active = _machines.where((m) => m.isActive).length;
    final maintenance = _machines.where((m) => m.isMaintenance).length;
    final inoperative = (total - active - maintenance).clamp(0, total);

    String pct(int v) => '${((v / total) * 100).toStringAsFixed(1)}%';

    final weekRange = _weekRangeText(_weekDate);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Nos alegra tenerte de nuevo!',
            style: TextStyle(
              color: Color(0xFF5B62B3),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            username,
            style: const TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w800,
              fontSize: 38 / 2,
            ),
          ),
          const SizedBox(height: 14),
          _weekSwitcher(weekRange),
          const SizedBox(height: 16),
          SizedBox(
            height: 114,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _kpiCard(
                  title: 'MTBF Promedio',
                  value: '${(240 + active * 20).toStringAsFixed(0)} h',
                  color: const Color(0xFF1F56A0),
                ),
                const SizedBox(width: 12),
                _kpiCard(
                  title: 'MTTR Promedio',
                  value: '${(2.5 + maintenance * 0.5).toStringAsFixed(1)} h',
                  color: const Color(0xFFECA6BB),
                ),
                const SizedBox(width: 12),
                _kpiCard(
                  title: 'Órdenes',
                  value: '${_machines.length * 2}',
                  color: const Color(0xFF5B62B3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _summaryPanel(
            title: 'Estado general de las maquinarias',
            rows: <_SummaryRow>[
              _SummaryRow('Máquinas operativas', pct(active), const Color(0xFFECA6BB)),
              _SummaryRow('Máquinas en mantenimiento', pct(maintenance), const Color(0xFFE9EEF7)),
              _SummaryRow('Máquinas inoperativas', pct(inoperative), const Color(0xFFECA6BB)),
            ],
          ),
          const SizedBox(height: 14),
          _summaryPanel(
            title: 'Frecuencia de mantenimientos',
            rows: const <_SummaryRow>[
              _SummaryRow('Mantenimientos preventivos', '60%', Color(0xFFECA6BB)),
              _SummaryRow('Mantenimientos correctivos', '40%', Color(0xFFE9EEF7)),
              _SummaryRow('Mantenimientos predictivos', '0%', Color(0xFFECA6BB)),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Notificaciones',
            style: TextStyle(
              color: Color(0xFF5B62B3),
              fontWeight: FontWeight.w700,
              fontSize: 30 / 2,
            ),
          ),
          const SizedBox(height: 10),
          _notification(
            title: 'Alerta de Mantenimiento',
            body: 'La máquina A98D2 presenta fallas en su funcionamiento.',
            icon: Icons.warning_rounded,
            accent: const Color(0xFFECA6BB),
          ),
          const SizedBox(height: 10),
          _notification(
            title: 'Órdenes pendientes',
            body: 'Tienes 3 órdenes de trabajo esperando asignación de técnicos.',
            icon: Icons.notifications,
            accent: const Color(0xFF5B62B3),
          ),
          const SizedBox(height: 10),
          _notification(
            title: 'Mantenimiento programado',
            body: 'La máquina F34G5 se encuentra en mantenimiento.',
            icon: Icons.calendar_month,
            accent: const Color(0xFF5B62B3),
          ),
        ],
      ),
    );
  }

  Widget _weekSwitcher(String weekRange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9EF)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => setState(() => _weekDate = _weekDate.subtract(const Duration(days: 7))),
            icon: const Icon(Icons.chevron_left, color: Color(0xFF5B62B3)),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  DateFormat('MMMM', 'es').format(_weekDate),
                  style: const TextStyle(
                    color: Color(0xFF2E59B1),
                    fontWeight: FontWeight.w700,
                    fontSize: 30 / 2,
                  ),
                ),
                Text(
                  weekRange,
                  style: const TextStyle(color: Color(0xFF86A1D9)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _weekDate = _weekDate.add(const Duration(days: 7))),
            icon: const Icon(Icons.chevron_right, color: Color(0xFF5B62B3)),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16 / 2)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 56 / 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel({
    required String title,
    required List<_SummaryRow> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF74A5E8),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 140),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: row.dot,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(color: Color(0xFF6E7480), fontSize: 30 / 2),
                    ),
                  ),
                  Text(
                    row.value,
                    style: const TextStyle(
                      color: Color(0xFF232A36),
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

  Widget _notification({
    required String title,
    required String body,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9EF)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 30 / 2,
                  ),
                ),
                Text(body, style: const TextStyle(color: Color(0xFF6E7480))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekRangeText(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
  }
}

class _SummaryRow {
  const _SummaryRow(this.label, this.value, this.dot);

  final String label;
  final String value;
  final Color dot;
}
