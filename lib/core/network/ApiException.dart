class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message, details: $details)';
  }
}
