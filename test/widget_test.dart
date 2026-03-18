import 'package:flutter_test/flutter_test.dart';
import 'package:mijigi/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MijigiApp());
    expect(find.text('Mijigi'), findsOneWidget);
  });
}
