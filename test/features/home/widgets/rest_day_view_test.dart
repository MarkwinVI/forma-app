import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/widgets/rest_day_view.dart';

/// The rest day fills the viewport and never scrolls, so everything under the
/// rings is fixed height — the rings have to absorb whatever is left, however
/// little that is.
void main() {
  Widget host({required double height}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 349,
            height: height,
            child: const RestDayView(
              nextTitle: 'Lower Day',
              nextWhen: 'tomorrow',
              onTrainSomethingElse: _noop,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('fits the height the Train tab gives it', (tester) async {
    await tester.pumpWidget(host(height: 577));
    expect(find.text('Nothing to do today'), findsOneWidget);
  });

  // The smallest Train tab body a supported phone gives it.
  testWidgets('fits a short viewport too', (tester) async {
    await tester.pumpWidget(host(height: 500));
    expect(find.text('Nothing to do today'), findsOneWidget);
  });
}

void _noop() {}
