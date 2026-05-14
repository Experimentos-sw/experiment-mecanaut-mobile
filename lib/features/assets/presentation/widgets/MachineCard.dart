import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mecanaut_mobile/core/widgets/EntityCard.dart';
import 'package:mecanaut_mobile/features/assets/data/services/MachinesService.dart';
import 'package:mecanaut_mobile/features/assets/presentation/widgets/StatusBadge.dart';

class MachineCard extends StatelessWidget {
  const MachineCard({
    super.key,
    required this.machine,
    required this.plantLabel,
    required this.lineLabel,
    required this.onDetailTap,
    this.onStartMaintenance,
    this.onCompleteMaintenance,
    this.onAssignLine,
  });

  final MachineItem machine;
  final String plantLabel;
  final String lineLabel;
  final VoidCallback onDetailTap;
  final VoidCallback? onStartMaintenance;
  final VoidCallback? onCompleteMaintenance;
  final VoidCallback? onAssignLine;

  @override
  Widget build(BuildContext context) {
    return EntityCard(
      badge: Text('ID: ${machine.id}', style: const TextStyle(color: Color(0xFF7E879A))),
      trailing: StatusBadge(text: _statusLabel(machine.status)),
      title: machine.model.isNotEmpty ? machine.model : machine.name,
      subtitle: machine.name,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          Text('Planta: $plantLabel'),
          Text('Linea: $lineLabel'),
          Text(
            'Ultimo mant: ${machine.lastMaintenanceDate == null ? '-' : DateFormat('dd/MM/yyyy').format(machine.lastMaintenanceDate!)}',
            style: const TextStyle(color: Color(0xFF6E7392)),
          ),
          if (machine.powerConsumption > 0)
            Text('Potencia: ${machine.powerConsumption.toStringAsFixed(0)} kW'),
        ],
      ),
      actions: Row(
        children: <Widget>[
          if (onStartMaintenance != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onStartMaintenance,
                child: const Text('Iniciar Mant.'),
              ),
            ),
          if (onCompleteMaintenance != null) ...<Widget>[
            if (onStartMaintenance != null) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onCompleteMaintenance,
                child: const Text('Completar'),
              ),
            ),
          ],
          if (onAssignLine != null) ...<Widget>[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAssignLine,
              icon: const Icon(Icons.alt_route),
              tooltip: 'Asignar a linea',
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: onDetailTap,
            icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF5B62B3)),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    if (status.toLowerCase() == 'active') return 'Activo';
    if (status.toLowerCase() == 'maintenance') return 'Mantenimiento';
    if (status.toLowerCase() == 'inactive') return 'Inactivo';
    return status;
  }
}

