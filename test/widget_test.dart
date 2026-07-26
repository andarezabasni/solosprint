import 'package:flutter_test/flutter_test.dart';
import 'package:solosprint/main.dart';

void main() {
  testWidgets('App renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const SoloSprintApp());
    expect(find.text('Home'), findsWidgets);
  });
}
