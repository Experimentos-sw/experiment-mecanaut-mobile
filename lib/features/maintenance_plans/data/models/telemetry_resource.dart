class TelemetryResource {
  final String experimentName;
  final String variant;
  final String actionType;
  final int? durationMilliseconds;
  final bool isSuccess;
  final String additionalData;

  TelemetryResource({
    required this.experimentName,
    required this.variant,
    required this.actionType,
    this.durationMilliseconds,
    required this.isSuccess,
    this.additionalData = '{}',
  });

  Map<String, dynamic> toMap() {
    return {
      'experimentName': experimentName,
      'variant': variant,
      'actionType': actionType,
      'durationMilliseconds': durationMilliseconds,
      'isSuccess': isSuccess,
      'additionalData': additionalData,
    };
  }
}
