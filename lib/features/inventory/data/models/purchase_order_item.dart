class PurchaseOrderItem {
  PurchaseOrderItem({
    required this.id,
    required this.orderNumber,
    required this.inventoryPartId,
    required this.quantity,
    required this.totalPrice,
    required this.orderDate,
    required this.deliveryDate,
    required this.status,
    required this.plantId,
  });

  final int id;
  final String orderNumber;
  final int inventoryPartId;
  final int quantity;
  final double totalPrice;
  final DateTime? orderDate;
  final DateTime? deliveryDate;
  final String status;
  final int plantId;

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      orderNumber: map['orderNumber']?.toString() ?? '',
      inventoryPartId: (map['inventoryPartId'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      orderDate: map['orderDate'] != null ? DateTime.tryParse(map['orderDate'].toString()) : null,
      deliveryDate: map['deliveryDate'] != null ? DateTime.tryParse(map['deliveryDate'].toString()) : null,
      status: map['status']?.toString() ?? '',
      plantId: (map['plantId'] as num?)?.toInt() ?? 0,
    );
  }
}

class PurchaseOrderCreateRequest {
  PurchaseOrderCreateRequest({
    required this.orderNumber,
    required this.inventoryPartId,
    required this.quantity,
    required this.totalPrice,
    required this.plantId,
    required this.deliveryDate,
  });

  final String orderNumber;
  final int inventoryPartId;
  final int quantity;
  final double totalPrice;
  final int plantId;
  final DateTime deliveryDate;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderNumber': orderNumber,
      'inventoryPartId': inventoryPartId,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'plantId': plantId,
      'deliveryDate': deliveryDate.toIso8601String(),
    };
  }
}
