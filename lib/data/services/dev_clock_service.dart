import 'package:shared_preferences/shared_preferences.dart';

/// Persisted local clock offset for developer testing. Production data keeps
/// its real timestamps; screens that opt into this service behave as if local
/// time has moved forward.
class DevClockService {
  static const _offsetKey = 'dev_clock_offset_minutes_v1';

  static bool _loaded = false;
  static Duration _offset = Duration.zero;

  Future<Duration> loadOffset() async {
    if (_loaded) return _offset;
    final prefs = await SharedPreferences.getInstance();
    _offset = Duration(minutes: prefs.getInt(_offsetKey) ?? 0);
    _loaded = true;
    return _offset;
  }

  DateTime now() => DateTime.now().add(_offset);

  Future<DateTime> loadNow() async {
    await loadOffset();
    return now();
  }

  Future<Duration> advanceBy(Duration duration) async {
    await loadOffset();
    _offset += duration;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offsetKey, _offset.inMinutes);
    return _offset;
  }

  Future<void> reset() async {
    _offset = Duration.zero;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offsetKey);
  }
}
