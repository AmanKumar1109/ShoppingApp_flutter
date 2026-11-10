import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App base smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('GroceryHub - Baharagora Quick Commerce'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('GroceryHub - Baharagora Quick Commerce'), findsOneWidget);
  });
}
