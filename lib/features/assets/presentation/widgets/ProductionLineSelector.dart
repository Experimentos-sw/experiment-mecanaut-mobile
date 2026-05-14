import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/features/assets/data/services/ProductionLinesService.dart';

class ProductionLineSelector extends StatelessWidget {
  const ProductionLineSelector({
    super.key,
    required this.lines,
    required this.selectedLineId,
    required this.onChanged,
    this.label = 'Linea de produccion',
    this.enabled = true,
    this.allowAll = true,
  });

  final List<ProductionLineItem> lines;
  final int? selectedLineId;
  final ValueChanged<int?> onChanged;
  final String label;
  final bool enabled;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<int?>>[
      if (allowAll) const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
      ...lines.map((line) => DropdownMenuItem<int?>(
            value: line.id,
            child: Text('${line.code} - ${line.name}'),
          )),
    ];
    return DropdownButtonFormField<int?>(
      initialValue: selectedLineId,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }
}

