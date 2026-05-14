class PlantItem {
  PlantItem({
    required this.id,
    required this.name,
    this.address = '',
    this.city = '',
    this.country = '',
    this.phone = '',
    this.email = '',
    this.active = true,
  });

  final int id;
  final String name;
  final String address;
  final String city;
  final String country;
  final String phone;
  final String email;
  final bool active;

  factory PlantItem.fromMap(Map<String, dynamic> map) {
    return PlantItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      active: map['active'] as bool? ?? true,
    );
  }
}
