import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/app.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const PsxMpqConverterApp());
    expect(find.text('PSX MPQ Converter'), findsOneWidget);
  });
}
