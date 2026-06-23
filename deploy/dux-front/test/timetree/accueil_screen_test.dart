import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/presentation/screens/accueil_screen.dart';

void main() {
  testWidgets('Timetree Accueil screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TimetreeAccueilScreen()));
    expect(find.text('TimeTree Accueil'), findsOneWidget);
  });
}
