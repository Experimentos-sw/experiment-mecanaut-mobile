import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/auth/presentation/screens/LoginScreen.dart';
import 'package:mecanaut_mobile/features/auth/presentation/screens/RegisterScreen.dart';
import 'package:mecanaut_mobile/features/assets/presentation/screens/MachineMetricsScreen.dart';
import 'package:mecanaut_mobile/features/assets/presentation/screens/MachineryScreen.dart';
import 'package:mecanaut_mobile/features/assets/presentation/screens/PlantsScreen.dart';
import 'package:mecanaut_mobile/features/assets/presentation/screens/ProductionLinesScreen.dart';
import 'package:mecanaut_mobile/features/home/presentation/screens/HomeScreen.dart';
import 'package:mecanaut_mobile/features/inventory/presentation/screens/InventoryScreen.dart';
import 'package:mecanaut_mobile/features/inventory/presentation/screens/PurchaseOrdersScreen.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/presentation/screens/MaintenancePlansScreen.dart';
import 'package:mecanaut_mobile/features/personnel/presentation/screens/PersonnelScreen.dart';
import 'package:mecanaut_mobile/features/settings/presentation/screens/SettingsScreen.dart';
import 'package:mecanaut_mobile/features/work_orders/presentation/screens/WorkOrdersScreen.dart';
import 'package:mecanaut_mobile/features/execution/presentation/screens/ExecutionScreen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String workOrders = '/orden-trabajo';
  static const String execution = '/ejecucion';
  static const String weeklyCalendar = '/calendario-semanal';
  static const String monthlyCalendar = '/calendario-mensual';
  static const String inventory = '/inventario-repuestos';
  static const String purchaseOrders = '/orden-compra';
  static const String machinery = '/gestion-maquinarias';
  static const String machineMetrics = '/machine-metrics';
  static const String productionLines = '/gestion-lineas-produccion';
  static const String plants = '/plantas';
  static const String maintenancePlan = '/plan-mantenimiento';
  static const String personnel = '/administracion-personal';
  static const String settings = '/configuracion';
  static const String profile = '/perfil';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authSession,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: LoadingView(message: 'Inicializando sesion...'),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.workOrders,
        builder: (_, __) => const WorkOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.execution,
        builder: (_, __) => const ExecutionScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyCalendar,
        builder: (_, __) => const WeeklyCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.monthlyCalendar,
        builder: (_, __) => const MonthlyCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (_, __) => const InventoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.purchaseOrders,
        builder: (_, __) => const PurchaseOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.machinery,
        builder: (_, __) => const MachineryScreen(),
      ),
      GoRoute(
        path: AppRoutes.machineMetrics,
        builder: (_, __) => const MachineMetricsScreen(),
      ),
      GoRoute(
        path: AppRoutes.productionLines,
        builder: (_, __) => const ProductionLinesScreen(),
      ),
      GoRoute(path: AppRoutes.plants, builder: (_, __) => const PlantsScreen()),
      GoRoute(
        path: AppRoutes.maintenancePlan,
        builder: (_, __) => const MaintenancePlansScreen(),
      ),
      GoRoute(
        path: AppRoutes.personnel,
        builder: (_, __) => const PersonnelScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool initialized = authSession.isInitialized;
      final bool hasToken = authSession.isAuthenticated;
      final String location = state.matchedLocation;

      final bool isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;
      final bool isSplashRoute = location == AppRoutes.splash;
      if (!initialized) {
        return isSplashRoute ? null : AppRoutes.splash;
      }

      if (!hasToken) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      if (isAuthRoute || isSplashRoute) {
        return AppRoutes.home;
      }

      return null;
    },
  );
});
