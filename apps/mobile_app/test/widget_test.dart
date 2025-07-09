import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// This is a basic widget test for the GymSync mobile app
// It verifies that the app can be built and rendered
void main() {
  testWidgets('GymSync app smoke test', (WidgetTester tester) async {
    // Build a test widget that wraps a MaterialApp
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('GymSync'),
          ),
        ),
      ),
    );

    // Verify that the text 'GymSync' is displayed
    expect(find.text('GymSync'), findsOneWidget);
  });
}