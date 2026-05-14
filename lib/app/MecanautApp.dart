import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mecanaut_mobile/app/AppRouter.dart';
import 'package:mecanaut_mobile/app/AppTheme.dart';

class MecanautApp extends ConsumerWidget {
  const MecanautApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Mecanaut',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      locale: const Locale('es', 'PE'),
      supportedLocales: const <Locale>[Locale('es', 'PE'), Locale('en', 'US')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
