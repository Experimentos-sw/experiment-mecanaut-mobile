import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/features/inventory/data/models/plant_item.dart';

class PlantSelector extends StatelessWidget {
  const PlantSelector({
    super.key,
    required this.plants,
    required this.selectedPlantId,
    required this.onChanged,
    this.label = 'Planta',
  });

  final List<PlantItem> plants;
  final int? selectedPlantId;
  final ValueChanged<int?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selectedPlantId,
      decoration: InputDecoration(labelText: label),
      items: plants
          .map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

