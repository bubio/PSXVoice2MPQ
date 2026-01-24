import 'package:flutter_test/flutter_test.dart';
import 'package:psx_mpq_converter/app.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const PsxMpqConverterApp());
    expect(find.text('PSX MPQ Converter'), findsOneWidget);
  });
}
