import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppSidebarMenu extends StatefulWidget {
  const AppSidebarMenu({
    super.key,
    required this.currentRoute,
    required this.userName,
    required this.roles,
    required this.onLogout,
  });

  final String currentRoute;
  final String userName;
  final List<String> roles;
  final VoidCallback onLogout;

  @override
  State<AppSidebarMenu> createState() => _AppSidebarMenuState();
}

class _AppSidebarMenuState extends State<AppSidebarMenu> {
  bool _assetExpanded = true;
  bool _inventoryExpanded = true;

  bool get _isTechnical => widget.roles.contains('RoleTechnical');

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF6DA0E1), Color(0xFF5B62B3)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 32,
                    child: Image.asset(
                      'assets/images/logo_white.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userName.isNotEmpty ? widget.userName : 'Usuario',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: <Widget>[
                  _item(
                    context,
                    label: 'Inicio',
                    route: '/',
                    icon: Icons.home_outlined,
                  ),
                  _expandableHeader(
                    icon: Icons.precision_manufacturing_outlined,
                    title: 'Gestion de Activos',
                    expanded: _assetExpanded,
                    onTap: () =>
                        setState(() => _assetExpanded = !_assetExpanded),
                  ),
                  if (_assetExpanded) ...<Widget>[
                    _subItem(
                      context,
                      label: 'Maquinarias',
                      route: '/gestion-maquinarias',
                    ),
                    _subItem(
                      context,
                      label: 'Metricas de Maquina',
                      route: '/machine-metrics',
                    ),
                    _subItem(
                      context,
                      label: 'Lineas de Produccion',
                      route: '/gestion-lineas-produccion',
                    ),
                    _subItem(context, label: 'Plantas', route: '/plantas'),
                  ],
                  _expandableHeader(
                    icon: Icons.inventory_2_outlined,
                    title: 'Inventario',
                    expanded: _inventoryExpanded,
                    onTap: () => setState(
                      () => _inventoryExpanded = !_inventoryExpanded,
                    ),
                  ),
                  if (_inventoryExpanded) ...<Widget>[
                    _subItem(
                      context,
                      label: 'Repuestos',
                      route: '/inventario-repuestos',
                    ),
                    _subItem(
                      context,
                      label: 'Ordenes de Compra',
                      route: '/orden-compra',
                    ),
                  ],
                  _item(
                    context,
                    label: 'Ordenes de Trabajo',
                    route: '/orden-trabajo',
                    icon: Icons.assignment_outlined,
                  ),
                  if (_isTechnical)
                    _item(
                      context,
                      label: 'Ejecucion',
                      route: '/ejecucion',
                      icon: Icons.play_circle_outline,
                    ),
                  _item(
                    context,
                    label: 'Planes de Mantenimiento',
                    route: '/plan-mantenimiento',
                    icon: Icons.build_circle_outlined,
                  ),
                  if (!_isTechnical)
                    _item(
                      context,
                      label: 'Administracion de Personal',
                      route: '/administracion-personal',
                      icon: Icons.groups_2_outlined,
                    ),
                  _item(
                    context,
                    label: 'Configuracion',
                    route: '/configuracion',
                    icon: Icons.settings_outlined,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFD7465E)),
              title: const Text('Cerrar sesion'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String label,
    required String route,
    required IconData icon,
  }) {
    final selected = widget.currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade700,
      ),
      title: Text(label),
      selected: selected,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.of(context).pop();
        if (route != widget.currentRoute) {
          context.go(route);
        }
      },
    );
  }

  Widget _subItem(
    BuildContext context, {
    required String label,
    required String route,
  }) {
    final selected = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: ListTile(
        dense: true,
        title: Text(label, style: const TextStyle(fontSize: 14)),
        selected: selected,
        selectedTileColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.of(context).pop();
          if (route != widget.currentRoute) {
            context.go(route);
          }
        },
      ),
    );
  }

  Widget _expandableHeader({
    required IconData icon,
    required String title,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      onTap: onTap,
    );
  }
}
