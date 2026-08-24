import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/app_nav_bar.dart';

/// The tab bar tells a screen reader which tab is which, how many there are,
/// and which one is open.
void main() {
  testWidgets('each tab is a button that says its place and whether it is on',
      (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppNavBar(
            currentIndex: 1,
            onTap: (index) => tapped = index,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Train, tab 2 of 4')),
      matchesSemantics(
        label: 'Train, tab 2 of 4',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Progress, tab 1 of 4')),
      matchesSemantics(
        label: 'Progress, tab 1 of 4',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Profile, tab 4 of 4'));
    expect(tapped, 3);
    handle.dispose();
  });

  testWidgets('the tab row is at least 49pt tall above the safe area',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppNavBar(currentIndex: 0, onTap: _noop),
        ),
      ),
    );
    final row = tester.getSize(find.text('Train').first);
    expect(row.height, greaterThan(0));
    // The whole item, icon to label, is the tap target.
    final item = tester.getSize(
      find
          .ancestor(
            of: find.text('Train'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(item.height, greaterThanOrEqualTo(49));
  });
}

void _noop(int _) {}
