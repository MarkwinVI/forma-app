import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/polished.dart';

/// Every tappable thing in the app is built on Pressable, so the button trait
/// has to live there: a screen reader hears "<label>, button", not a stray
/// piece of text beside an unnamed tap region.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('a Pressable with text reads as a button named by that text',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(Pressable(onTap: () {}, child: const Text('Start workout'))),
    );

    expect(
      tester.getSemantics(find.text('Start workout')),
      matchesSemantics(
        label: 'Start workout',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('an explicit semanticLabel names an icon-only Pressable',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Pressable(
          onTap: () {},
          semanticLabel: 'Back',
          child: const Icon(Icons.chevron_left_rounded),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(Pressable)),
      matchesSemantics(
        label: 'Back',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a disabled PillButton still reads as a button, disabled',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const PillButton(label: 'Save')));

    expect(
      tester.getSemantics(find.byType(PillButton)),
      matchesSemantics(
        label: 'Save',
        isButton: true,
        isEnabled: false,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a Pressable with no onTap and no label is plain content',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const Pressable(child: Text('Rest day'))));

    expect(
      tester.getSemantics(find.text('Rest day')),
      matchesSemantics(label: 'Rest day', isButton: false),
    );
    handle.dispose();
  });

  testWidgets('the back, close and header circle buttons are 44pt targets',
      (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            SubScreenHeader(title: 'Settings', onBack: () {}),
            HeaderCircleButton(
              icon: Icons.settings_outlined,
              semanticLabel: 'Settings',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    Size targetAround(IconData icon) => tester.getSize(
          find
              .ancestor(
                of: find.byIcon(icon),
                matching: find.byType(SizedBox),
              )
              .first,
        );
    expect(targetAround(Icons.chevron_left_rounded), const Size(44, 44));
    expect(targetAround(Icons.settings_outlined), const Size(44, 44));
    expect(find.bySemanticsLabel('Back'), findsWidgets);
    expect(find.bySemanticsLabel('Settings'), findsWidgets);
  });

  testWidgets('TextAction is a 44pt tall accent text button', (tester) async {
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topCenter,
          child: TextAction(label: 'Retry', onTap: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(TextAction)).height, 44);
    expect(find.text('Retry'), findsOneWidget);
  });
}
