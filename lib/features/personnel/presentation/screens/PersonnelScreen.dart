import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/user_item.dart';
import 'package:mecanaut_mobile/features/personnel/data/services/RolesService.dart';
import 'package:mecanaut_mobile/features/personnel/data/services/UsersService.dart';
import 'package:mecanaut_mobile/features/personnel/presentation/widgets/NewPersonnelModal.dart';

class PersonnelScreen extends ConsumerStatefulWidget {
  const PersonnelScreen({super.key});

  @override
  ConsumerState<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends ConsumerState<PersonnelScreen> {
  late final UsersService _usersService;
  late final RolesService _rolesService;

  bool _loading = true;
  bool _creating = false;
  String? _error;
  List<UserItem> _users = <UserItem>[];
  List<String> _roles = <String>['RoleTechnical', 'RoleAdmin'];
  final TextEditingController _searchController = TextEditingController();
  int? _expandedUserId;

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _usersService = UsersService(dio);
    _rolesService = RolesService(dio);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await _rolesService.getRoles();
      final users = await _usersService.getUsers();
      setState(() {
        _roles = roles.isEmpty ? _roles : roles.map((e) => e.name).toList();
        _users = users;
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
        _error = 'Error inesperado al cargar personal.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Administracion del personal',
      currentRoute: '/administracion-personal',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Cargando personal...');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _loadData);
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = _users.where((u) {
      final roleText = u.roles.join(',').toLowerCase();
      return u.fullName.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          roleText.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Administracion del personal',
          style: TextStyle(
            fontSize: 36 / 2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F56A0),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gestiona tu equipo y tecnicos.',
          style: TextStyle(color: Color(0xFF4A4A4A)),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar personal...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.filter_list),
                label: const Text('Filtro'),
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
            label: const Text('Nuevo Personal'),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: Center(child: Text('No se encontro personal para mostrar.')),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final user = filtered[index];
                final expanded = _expandedUserId == user.id;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E5E8)),
                  ),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        onTap: () {
                          setState(
                            () => _expandedUserId = expanded ? null : user.id,
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE9EDF7),
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: Color(0xFF1F56A0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName
                              : user.username,
                          style: const TextStyle(
                            color: Color(0xFF1F56A0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${user.username} • ${_roleLabel(user.roles)}',
                        ),
                        trailing: Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: const Color(0xFFBBC1CE),
                        ),
                      ),
                      if (expanded) _expandedPanel(user),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _expandedPanel(UserItem user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            children: user.roles
                .map(
                  (r) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E7FA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(_roleLabel(<String>[r])),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text('Correo: ${user.email}'),
          const SizedBox(height: 4),
          Text('Usuario: ${user.username}'),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: null,
            child: const Text('Editar Perfil (proximamente)'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateModal() async {
    final result = await showDialog<NewPersonnelResult>(
      context: context,
      barrierDismissible: !_creating,
      builder: (_) =>
          NewPersonnelModal(isSubmitting: _creating, availableRoles: _roles),
    );

    if (result == null) {
      return;
    }

    setState(() => _creating = true);
    try {
      await _usersService.createUser(result.request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal creado correctamente.')),
        );
      }
      await _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      final unauthorized = e.statusCode == 401 || e.statusCode == 403;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unauthorized
                ? 'No tienes permisos para crear personal (rol Admin requerido).'
                : e.message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  String _roleLabel(List<String> roles) {
    if (roles.contains('RoleAdmin')) return 'Administrador';
    if (roles.contains('RoleTechnical')) return 'Tecnico';
    return roles.join(', ');
  }
}
