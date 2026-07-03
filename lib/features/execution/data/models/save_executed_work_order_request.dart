class SaveExecutedWorkOrderRequest {
  SaveExecutedWorkOrderRequest({
    required this.code,
    required this.annotations,
    required this.executionDate,
    required this.productionLineId,
    required this.intervenedMachineIds,
    required this.assignedTechnicianIds,
    required this.executedTasks,
    required this.usedProducts,
    required this.files,
    required this.workOrderId,
  });

  final String code;
  final String annotations;
  final String executionDate;
  final int productionLineId;
  final List<int> intervenedMachineIds;
  final List<int> assignedTechnicianIds;
  final List<String> executedTasks;
  final List<ExecutionProductRequest> usedProducts;
  final List<String> files;
  final int workOrderId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'annotations': annotations,
      'executionDate': executionDate,
      'productionLineId': productionLineId,
      'intervenedMachineIds': intervenedMachineIds,
      'assignedTechnicianIds': assignedTechnicianIds,
      'executedTasks': executedTasks,
      'usedProducts': usedProducts.map((p) => p.toMap()).toList(),
      'files': files,
      'workOrderId': workOrderId,
    };
  }
}

class ExecutionProductRequest {
  ExecutionProductRequest({
    required this.productId,
    required this.quantity,
  });

  final int productId;
  final int quantity;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class ExecutedWorkOrderDto {
  ExecutedWorkOrderDto({
    required this.id,
    required this.code,
    required this.annotations,
    required this.executedTasks,
    required this.usedProducts,
    required this.executionImages,
  });

  final int id;
  final String code;
  final String annotations;
  final List<String> executedTasks;
  final List<ExecutionProductDto> usedProducts;
  final List<String> executionImages;

  factory ExecutedWorkOrderDto.fromMap(Map<String, dynamic> map) {
    return ExecutedWorkOrderDto(
      id: (map['id'] as num?)?.toInt() ?? 0,
      code: map['code']?.toString() ?? '',
      annotations: map['annotations']?.toString() ?? '',
      executedTasks: List<String>.from(map['executedTasks'] ?? []),
      usedProducts: List<Map<String, dynamic>>.from(map['usedProducts'] ?? [])
          .map(ExecutionProductDto.fromMap)
          .toList(),
      executionImages: List<String>.from(map['executionImages'] ?? []),
    );
  }
}

class ExecutionProductDto {
  ExecutionProductDto({
    required this.productId,
    required this.quantity,
  });

  final int productId;
  final int quantity;

  factory ExecutionProductDto.fromMap(Map<String, dynamic> map) {
    return ExecutionProductDto(
      productId: (map['productId'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
