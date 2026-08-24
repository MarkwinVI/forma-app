import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/format/dates.dart';

void main() {
  /// Pumps [onContext] under a German MaterialApp, optionally on a 24-hour
  /// clock, and hands back what it produced.
  Future<String> render(
    WidgetTester tester,
    String Function(BuildContext context) onContext, {
    bool use24Hour = false,
  }) async {
    late String out;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('de')],
        home: MediaQuery(
          data: MediaQueryData(alwaysUse24HourFormat: use24Hour),
          child: Builder(
            builder: (context) {
              out = onContext(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return out;
  }

  testWidgets('month names follow the app locale', (tester) async {
    final march = await render(
      tester,
      (context) => FormaDates.monthLong(context, DateTime(2026, 3, 5)),
    );
    expect(march, 'März');
  });

  testWidgets('time follows the 24-hour setting', (tester) async {
    final at = DateTime(2026, 8, 19, 14, 5);
    expect(
      await render(tester, (c) => FormaDates.time(c, at), use24Hour: true),
      '14:05',
    );
  });

  testWidgets('weekday letter and long name agree on Monday-first index',
      (tester) async {
    final letter = await render(tester, (c) => FormaDates.weekdayLetter(c, 0));
    final name = await render(tester, (c) => FormaDates.weekdayLongByIndex(c, 0));
    expect(letter, 'M');
    expect(name, 'Montag');
  });
}
