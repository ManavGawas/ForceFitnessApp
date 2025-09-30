// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymmate/main.dart';
import 'package:gymmate/services/firebase_service.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    // Initialize Firebase so providers using FirebaseAuth don't throw in tests
    try {
      await FirebaseService.init();
    } catch (_) {}
    await tester.pumpWidget(const GymMateApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
