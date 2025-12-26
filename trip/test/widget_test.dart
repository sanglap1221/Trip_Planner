// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:trip/src/app.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
  });

  testWidgets('App launches and shows login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TripApp());
    await tester.pumpAndSettle();

    // Verify that the login page elements are present
    expect(find.text('Login'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Login form has expected widgets', (WidgetTester tester) async {
    await tester.pumpWidget(const TripApp());
    await tester.pumpAndSettle();

    // Find text fields
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Find login button
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    // Find signup link
    expect(find.text('Create an account'), findsOneWidget);
  });
}
