import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mecanaut_mobile/app/MecanautApp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_PE';
  await initializeDateFormatting('es_PE');
  runApp(const ProviderScope(child: MecanautApp()));
}
