class AppConfig {
  AppConfig._();

  // static const String defaultApiBaseUrl =
  //     'https://mecanaut-api-csdaced4hjenb0d4.canadacentral-01.azurewebsites.net';
  static const String defaultApiBaseUrl = 'http://localhost:5128';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );
}

class ApiPaths {
  ApiPaths._();
  static const String signIn = '/api/v1/authentication/sign-in';
  static const String signUp = '/api/v1/authentication/sign-up';
  static const String users = '/api/v1/users';
  static const String roles = '/api/v1/roles';
  static const String machines = '/api/v1/machines';
  static const String plants = '/api/v1/plants';
  static const String productionLines = '/api/v1/production-lines';
  static const String workOrders = '/api/v1/work-orders';
  static const String executedWorkOrders = '/api/v1/executed-work-orders';
  static const String inventoryParts = '/api/v1/inventory-parts';
  static const String purchaseOrders = '/api/purchase-orders';
  static const String metricDefinitions = '/api/v1/metric-definitions';
  static const String dynamicMaintenancePlans =
      '/api/v1/dynamic-maintenance-plans';
  static const String skills = '/api/v1/skills';
}
