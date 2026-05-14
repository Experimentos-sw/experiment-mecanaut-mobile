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
import 'package:mecanaut_mobile/features/assets/data/services/PlantsService.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/NewPlantModal.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/StatusBadge.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

enum _PlantsFilter { all, active, inactive }

class PlantsScreen extends ConsumerStatefulWidget {
  const PlantsScreen({super.key});

  @override
  ConsumerState<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends ConsumerState<PlantsScreen> {
  late final PlantsService _service;
  bool _loading = true;
  String? _error;
  String _query = '';
  _PlantsFilter _filter = _PlantsFilter.all;
  List<PlantItem> _plants = <PlantItem>[];

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _service = PlantsService(dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await _service.getPlants();
      setState(() {
        _plants = plants;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudieron cargar plantas.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Plantas',
      currentRoute: '/plantas',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const LoadingView(message: 'Cargando plantas...');
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    final visiblePlants = _filteredPlants();
    final hasFilters = _query.trim().isNotEmpty || _filter != _PlantsFilter.all;

    return Column(
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar planta...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openFilter,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(_filterLabel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openCreatePlant,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Planta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: visiblePlants.isEmpty
              ? EmptyStateView(
                  title: hasFilters ? 'No se encontraron plantas' : 'Sin plantas',
                  message: hasFilters
                      ? 'Intenta ajustar la busqueda o el filtro.'
                      : 'No hay plantas registradas.',
                )
              : ListView.separated(
                  itemCount: visiblePlants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, int index) => _plantCard(visiblePlants[index]),
                ),
        ),
      ],
    );
  }

  List<PlantItem> _filteredPlants() {
    return _plants.where((plant) {
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          plant.name.toLowerCase().contains(q) ||
          plant.country.toLowerCase().contains(q) ||
          plant.city.toLowerCase().contains(q) ||
          plant.email.toLowerCase().contains(q);
      if (!matchesQuery) return false;

      switch (_filter) {
        case _PlantsFilter.all:
          return true;
        case _PlantsFilter.active:
          return plant.active;
        case _PlantsFilter.inactive:
          return !plant.active;
      }
    }).toList();
  }

  Widget _plantCard(PlantItem plant) {
    final infoParts = <String>[
      if (plant.address.trim().isNotEmpty) plant.address.trim(),
      if (plant.city.trim().isNotEmpty) plant.city.trim(),
      if (plant.email.trim().isNotEmpty) plant.email.trim(),
      if (plant.phone.trim().isNotEmpty) plant.phone.trim(),
    ];
    final infoText = infoParts.isEmpty ? '—' : infoParts.join(' · ');

    return EntityCard(
      leadingStripeColor: plant.active ? const Color(0xFF2BC866) : const Color(0xFF9CA3B5),
      badge: Text(
        'ID: ${plant.id}',
        style: const TextStyle(color: Color(0xFF7E879A), fontSize: 12),
      ),
      trailing: StatusBadge(text: plant.active ? 'Activa' : 'Inactiva'),
      title: plant.name,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _infoRow('Country', plant.country.trim().isEmpty ? '—' : plant.country),
          const SizedBox(height: 6),
          _infoRow('Active', plant.active ? 'Si' : 'No'),
          const SizedBox(height: 6),
          _infoRow('Info', infoText),
        ],
      ),
      actions: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _togglePlantStatus(plant),
          icon: Icon(plant.active ? Icons.pause_circle_outline : Icons.play_circle_outline),
          label: Text(plant.active ? 'Desactivar' : 'Activar'),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 62,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF7E879A),
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2A3140),
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFilter() async {
    final selected = await showModalBottomSheet<_PlantsFilter>(
      context: context,
      builder: (_) => AppBottomSheet(
        title: 'Filtro',
        onClose: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Todas'),
              trailing: _filter == _PlantsFilter.all ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(_PlantsFilter.all),
            ),
            ListTile(
              title: const Text('Activas'),
              trailing: _filter == _PlantsFilter.active ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(_PlantsFilter.active),
            ),
            ListTile(
              title: const Text('Inactivas'),
              trailing: _filter == _PlantsFilter.inactive ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(_PlantsFilter.inactive),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() => _filter = selected);
    }
  }

  Future<void> _openCreatePlant() async {
    final request = await showModalBottomSheet<CreatePlantRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        child: const NewPlantModal(),
        onClose: () => Navigator.of(context).pop(),
      ),
    );

    if (request == null) return;

    try {
      await _service.createPlant(request);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planta creada correctamente.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _togglePlantStatus(PlantItem plant) async {
    try {
      if (plant.active) {
        await _service.deactivatePlant(plant.id);
      } else {
        await _service.activatePlant(plant.id);
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  String get _filterLabel {
    switch (_filter) {
      case _PlantsFilter.all:
        return 'Filtro';
      case _PlantsFilter.active:
        return 'Activas';
      case _PlantsFilter.inactive:
        return 'Inactivas';
    }
  }
}
