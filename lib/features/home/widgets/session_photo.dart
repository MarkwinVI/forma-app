import 'package:flutter/material.dart';

/// A session's photo as a surface to set type on: the picture, cropped to
/// fill, under a wash that darkens toward the bottom where the words sit.
class SessionPhoto extends StatelessWidget {
  final String image;

  /// Where to hold the picture when it is cropped (-1 top … 1 bottom).
  final double focusY;
  final BorderRadius borderRadius;

  /// A flat dim instead of the bottom-heavy wash — for a thumbnail, which
  /// carries no type.
  final bool thumbnail;
  final Widget? child;

  const SessionPhoto({
    super.key,
    required this.image,
    this.focusY = 0,
    this.borderRadius = BorderRadius.zero,
    this.thumbnail = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111318),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            alignment: Alignment(0, focusY),
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: thumbnail ? const Color(0x2608090D) : null,
            gradient: thumbnail
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.3, 0.62, 1],
                    colors: [
                      Color(0x4708090D),
                      Color(0x0008090D),
                      Color(0x8C08090D),
                      Color(0xF008090D),
                    ],
                  ),
          ),
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// The small glass pill set on a photo: "10 MIN", "QUICK SESSION".
class PhotoPill extends StatelessWidget {
  final String label;

  const PhotoPill(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x8C0C0D12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.26,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}
