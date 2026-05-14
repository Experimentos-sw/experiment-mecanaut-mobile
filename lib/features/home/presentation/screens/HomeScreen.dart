import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/assets/data/services/PlantsService.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PlantsService _plantsService;

  bool _loading = true;
  String? _error;
  List<PlantItem> _plants = <PlantItem>[];
  int? _selectedPlantId;

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _plantsService = PlantsService(dio);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await _plantsService.getPlants();
      setState(() {
        _plants = plants;
        if (_selectedPlantId == null && plants.isNotEmpty) {
          _selectedPlantId = plants.first.id;
        }
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudieron cargar los datos de inicio.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Inicio',
      currentRoute: '/',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Cargando inicio...');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _loadData);
    }

    final auth = ref.watch(authSessionProvider);
    final username = auth.user?.username ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            username.isEmpty ? 'Welcome!' : 'Welcome, $username!',
            style: const TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 14),
          _buildTopControls(context),
          const SizedBox(height: 20),
          const Text(
            'Main Metrics',
            style: TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _metricCard(
            title: 'General Efficiency',
            value: '85.0%',
            trend: '-2%',
            details: const <String, String>{
              'Availability': '87.0%',
              'Performance': '82.0%',
              'Quality': '90.0%',
            },
            color: const Color(0xFF1F56A0),
          ),
          const SizedBox(height: 12),
          _metricCard(
            title: 'Downtime',
            value: '15.0 hrs',
            trend: '1%',
            details: const <String, String>{
              'Maintenance': '9.0 hrs',
              'Breakdowns': '4.5 hrs',
              'Setup': '1.5 hrs',
            },
            color: const Color(0xFFE79CB6),
          ),
          const SizedBox(height: 12),
          _metricCard(
            title: 'Orders Completed',
            value: '0',
            trend: '0%',
            details: const <String, String>{
              'On Time': '0',
              'Delayed': '0',
              'Critical': '0',
            },
            color: const Color(0xFF5B62B3),
          ),
          const SizedBox(height: 12),
          _metricCard(
            title: 'Maintenance Costs',
            value: r'$21,212',
            trend: '7%',
            details: const <String, String>{
              'Parts': r'$12,727',
              'Labor': r'$6,363',
              'Others': r'$2,121',
            },
            color: const Color(0xFF74A5E8),
          ),
          const SizedBox(height: 20),
          const Text(
            'Additional Metrics',
            style: TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _additionalMetricsGrid(),
          const SizedBox(height: 20),
          const Text(
            'Quick Access',
            style: TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _quickAccess(context),
          const SizedBox(height: 20),
          _statusCard(
            title: 'Equipment Status',
            action: 'View all',
            content: const Text('No critical equipment'),
          ),
          const SizedBox(height: 12),
          _statusCard(
            title: 'Inventory Health',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Wrap(
                  spacing: 12,
                  children: <Widget>[
                    _LegendDot(label: 'Critical', color: Color(0xFFE79CB6)),
                    _LegendDot(
                      label: 'Attention Required',
                      color: Color(0xFFF3B76A),
                    ),
                    _LegendDot(label: 'Normal', color: Color(0xFFB8D8FF)),
                  ],
                ),
                SizedBox(height: 10),
                Text('No inventory issues'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _statusCard(
            title: 'Recent Activity',
            action: 'View all',
            content: const Text('No recent activity'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Personal Summary',
            style: TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _personalSummaryCard(),
          const SizedBox(height: 20),
          const Text(
            'Quick Stats',
            style: TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _quickStatsGrid(),
          const SizedBox(height: 20),
          const Text(
            'System Health',
            style: TextStyle(
              color: Color(0xFF1F56A0),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _systemHealthGrid(),
        ],
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButtonFormField<int>(
          initialValue: _selectedPlantId,
          decoration: const InputDecoration(labelText: 'Select Plant'),
          items: _plants
              .map(
                (plant) => DropdownMenuItem<int>(
                  value: plant.id,
                  child: Text(plant.name),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _selectedPlantId = value),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (_, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () => context.go('/orden-trabajo'),
                    icon: const Icon(Icons.add),
                    label: const Text('New Order'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/orden-trabajo'),
                    icon: const Icon(Icons.add),
                    label: const Text('New Order'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String trend,
    required Map<String, String> details,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F56A0),
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                trend,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 30,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in details.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Color(0xFF7E8594)),
                    ),
                  ),
                  Text(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _additionalMetricsGrid() {
    final cards = <Widget>[
      _miniMetricCard(
        'Plant Performance',
        '0',
        'Active Plants',
        '85% Operational',
      ),
      _miniMetricCard(
        'Team Productivity',
        '92%',
        'This Week',
        '5% vs Last Week',
      ),
      _miniMetricCard('Maintenance Schedule', '12', 'This Month', 'On Track'),
      _miniMetricCard(
        'Cost Savings',
        r'45.000,00 US$',
        'This Quarter',
        '12% vs Last Quarter',
      ),
      _miniMetricCard('Safety Score', '98%', 'Incident Free', '156 days'),
      _miniMetricCard(
        'Energy Efficiency',
        '87%',
        'Power Optimization',
        '3% vs Last Month',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (_, index) => cards[index],
    );
  }

  Widget _miniMetricCard(
    String title,
    String value,
    String subtitle,
    String footer,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F56A0),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF7E8594), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            style: const TextStyle(color: Color(0xFF5B62B3), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _quickAccess(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _quickLink(
            context,
            'Maintenance',
            '/plan-mantenimiento',
            Icons.build_circle_outlined,
          ),
          const SizedBox(width: 10),
          _quickLink(
            context,
            'Inventory',
            '/inventario-repuestos',
            Icons.inventory_2_outlined,
          ),
          const SizedBox(width: 10),
          _quickLink(context, 'Reports', '/', Icons.assessment_outlined),
        ],
      ),
    );
  }

  Widget _quickLink(
    BuildContext context,
    String label,
    String route,
    IconData icon,
  ) {
    return SizedBox(
      width: 146,
      child: OutlinedButton.icon(
        onPressed: () => context.go(route),
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }

  Widget _statusCard({
    required String title,
    String? action,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F56A0),
                    fontSize: 17,
                  ),
                ),
              ),
              if (action != null)
                Text(action, style: const TextStyle(color: Color(0xFF5B62B3))),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _personalSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Team Performance',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            '85%',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 30,
              color: Color(0xFF1F56A0),
            ),
          ),
          Text('Goal: 90%'),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryStat(label: 'Completed Tasks', value: '28'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SummaryStat(label: 'In Progress', value: '15'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Tip: Review pending high-priority orders to improve response time.',
          ),
        ],
      ),
    );
  }

  Widget _quickStatsGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const <Widget>[
        _SummaryStat(label: 'Equipment Monitored', value: '0', width: 168),
        _SummaryStat(label: 'Low Stock Items', value: '0', width: 168),
        _SummaryStat(label: 'Pending Orders', value: '0', width: 168),
        _SummaryStat(label: 'Active Technicians', value: '8', width: 168),
      ],
    );
  }

  Widget _systemHealthGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const <Widget>[
        _SummaryStat(label: 'Operational', value: '0', width: 168),
        _SummaryStat(label: 'Attention Required', value: '0', width: 168),
        _SummaryStat(label: 'In Maintenance', value: '0', width: 168),
        _SummaryStat(label: 'Critical', value: '0', width: 168),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, this.width});

  final String label;
  final String value;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7E8594), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7E8594)),
        ),
      ],
    );
  }
}
