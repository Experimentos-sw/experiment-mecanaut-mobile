import 'package:flutter/material.dart';

class FilterChipItem<T> {
  FilterChipItem({required this.value, required this.label});

  final T value;
  final String label;
}

class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<FilterChipItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: items.map((item) {
        final active = item.value == selected;
        return ChoiceChip(
          label: Text(item.label),
          selected: active,
          onSelected: (_) => onSelected(item.value),
        );
      }).toList(),
    );
  }
}
