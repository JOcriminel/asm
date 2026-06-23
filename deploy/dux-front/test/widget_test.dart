import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/app.dart';

void main() {
  testWidgets('Splash screen smoke test — shows loading indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // The splash screen (DuxLoadingScreen) renders a LinearProgressIndicator
    // and animated "loading" text — not the static text "DUX".
    expect(find.byType(ProviderScope), findsOneWidget);
    // Verify the loading progress bar is present on the splash screen.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
