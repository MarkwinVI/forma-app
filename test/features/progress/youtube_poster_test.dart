import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_panels.dart';

/// YouTube's hqdefault poster is 4:3 with the 16:9 picture letterboxed
/// into it. The thumbnail sizes it so the picture alone covers the frame;
/// the black bars land outside, where the frame clips them.
void main() {
  const url = 'https://img.youtube.com/vi/abc/hqdefault.jpg';

  Future<Rect> imageRectIn(WidgetTester tester, Size frame) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox.fromSize(
          size: frame,
          child: const YouTubePoster(url: url),
        ),
      ),
    ));
    return tester.getRect(find.byType(Image));
  }

  /// The letterboxed 16:9 band inside the 4:3 image.
  Rect pictureOf(Rect image) {
    final bar = image.height / 8;
    return Rect.fromLTRB(
        image.left, image.top + bar, image.right, image.bottom - bar);
  }

  testWidgets('a 16:9 frame shows exactly the picture', (tester) async {
    final image = await imageRectIn(tester, const Size(320, 180));
    final framed = tester.getRect(find.byType(YouTubePoster));
    final picture = pictureOf(image);
    expect(picture.top, closeTo(framed.top, 0.01));
    expect(picture.bottom, closeTo(framed.bottom, 0.01));
    expect(picture.width, closeTo(framed.width, 0.01));
  });

  testWidgets('a narrower row thumbnail still keeps the bars out of frame',
      (tester) async {
    final image = await imageRectIn(tester, const Size(64, 40));
    final framed = tester.getRect(find.byType(YouTubePoster));
    final picture = pictureOf(image);
    // The picture covers the frame on every side: no bar can show.
    expect(picture.top, lessThanOrEqualTo(framed.top + 0.01));
    expect(picture.bottom, greaterThanOrEqualTo(framed.bottom - 0.01));
    expect(picture.left, lessThanOrEqualTo(framed.left + 0.01));
    expect(picture.right, greaterThanOrEqualTo(framed.right - 0.01));
  });

  test('only YouTube poster urls take the crop', () {
    expect(isYouTubePoster(url), isTrue);
    expect(isYouTubePoster('https://example.com/still.jpg'), isFalse);
  });
}
