// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rps/main.dart';

void main() {
  testWidgets('App loads code entry screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that code entry screen elements are present.
    expect(find.text('Photo Gallery'), findsOneWidget);
    expect(find.text('Enter Event Code'), findsOneWidget);
    expect(find.text('Access Photos'), findsOneWidget);
    
    // Verify input field exists
    expect(find.byType(TextField), findsOneWidget);
  });
}
