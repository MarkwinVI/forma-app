/// What the exercise detail view says about a movement: how to do it, what
/// every rep has to pass, and the demo that shows it.
///
/// Kept apart from [ExerciseCatalog], which says where a movement sits in a
/// tree. Both are generated from the same exercise sheet, but this is the
/// half a reader looks at and that half changes on its own schedule.
class ExerciseCoaching {
  /// Ordered steps, read as a numbered list. Three for most movements, four
  /// where the barbell lifts need a separate setup step.
  final List<String> howTo;

  /// The short lines every rep is judged against.
  final List<String> formChecks;

  /// YouTube demo for the movement. Some steps of a weighted ladder share
  /// one clip — there is a single demo of a weighted pull-up, not seven.
  final String videoUrl;

  /// Still frame, used until the video is ready and whenever it cannot load.
  final String imageUrl;

  const ExerciseCoaching({
    required this.howTo,
    required this.formChecks,
    required this.videoUrl,
    required this.imageUrl,
  });

  /// The eleven-character YouTube id inside [videoUrl], or null if the link
  /// is not one the player can take.
  String? get videoId {
    final match = RegExp(r'[?&]v=([\w-]{11})').firstMatch(videoUrl);
    return match?.group(1);
  }
}
