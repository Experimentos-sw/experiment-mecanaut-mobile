class InventoryPartItem {
  InventoryPartItem({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.currentStock,
    required this.minStock,
    required this.unitPrice,
    required this.stockStatus,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  final int currentStock;
  final int minStock;
  final double unitPrice;
  final String stockStatus;

  bool get isLowStock => currentStock < minStock;

  factory InventoryPartItem.fromMap(Map<String, dynamic> map) {
    return InventoryPartItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      currentStock: (map['currentStock'] as num?)?.toInt() ?? 0,
      minStock: (map['minStock'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      stockStatus: map['stockStatus']?.toString() ?? '',
    );
  }
}

class InventoryPartCreateRequest {
  InventoryPartCreateRequest({
    required this.code,
    required this.name,
    required this.description,
    required this.currentStock,
    required this.minStock,
    required this.unitPrice,
    required this.plantId,
  });

  final String code;
  final String name;
  final String description;
  final int currentStock;
  final int minStock;
  final double unitPrice;
  final int plantId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'description': description,
      'currentStock': currentStock,
      'minStock': minStock,
      'unitPrice': unitPrice,
      'plantId': plantId,
    };
  }
}

class InventoryPartUpdateRequest {
  InventoryPartUpdateRequest({
    this.description,
    this.currentStock,
    this.minStock,
    this.unitPrice,
  });

  final String? description;
  final int? currentStock;
  final int? minStock;
  final double? unitPrice;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'description': description,
      'currentStock': currentStock,
      'minStock': minStock,
      'unitPrice': unitPrice,
    };
  }
}
