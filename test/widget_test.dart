import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecanaut_mobile/app/MecanautApp.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MecanautApp()));
    expect(find.text('Inicializando sesion...'), findsOneWidget);
  });
}
