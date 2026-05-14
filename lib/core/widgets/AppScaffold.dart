import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/widgets/AppSidebarMenu.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
  });

  final String title;
  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          height: 30,
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1F56A0)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF1F56A0)),
            onPressed: () => context.go('/perfil'),
          ),
        ],
      ),
      drawer: AppSidebarMenu(
        currentRoute: currentRoute,
        userName: authSession.user?.username ?? '',
        roles: authSession.roles,
        onLogout: () async {
          await ref.read(authSessionProvider).signOut();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
