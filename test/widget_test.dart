import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/l10n/app_localizations.dart';

void main() {
  testWidgets('Localization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            // Test that we can access localized strings
            return Scaffold(
              body: Center(
                child: Text(AppLocalizations.of(context)!.settings),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the English translation is loaded
    expect(find.text('Settings'), findsOneWidget);
  });
}
