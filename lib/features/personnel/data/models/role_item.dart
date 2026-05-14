class RoleItem {
  RoleItem({required this.id, required this.name});

  final int id;
  final String name;

  factory RoleItem.fromMap(Map<String, dynamic> map) {
    return RoleItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
    );
  }
}
