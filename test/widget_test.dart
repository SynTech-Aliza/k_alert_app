import 'package:flutter_test/flutter_test.dart';
import 'package:k_alert_app/main.dart';

void main() {
  testWidgets('HomeScreen displays Hello World', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our 'Hello World!' text is displayed on screen.
    expect(find.text('Hello World!'), findsOneWidget);
  });
}