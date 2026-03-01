import 'package:flutter_test/flutter_test.dart';
import 'package:laukai/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LaukAiApp());
    expect(find.text('LaukAI'), findsOneWidget);
  });
}
