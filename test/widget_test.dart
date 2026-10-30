import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/app.dart';
import 'package:psxvoice2mpq/core/di/service_locator.dart';

void main() {
  setUpAll(setupServiceLocator);

  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PsxMpqConverterApp()));
    expect(find.text('PSXVoice2MPQ'), findsOneWidget);
  });
}
