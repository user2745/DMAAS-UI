import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AnonymousId {
  static const _key = 'dmaas_anonymous_id';
  static final _uuid = const Uuid();
  static String? _cached;

  /// Returns a stable anonymous id stored in SharedPreferences.
  static Future<String> getOrCreate() async {
    if (_cached != null && _cached!.isNotEmpty) {
      return _cached!;
    }
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }
    final generated = _uuid.v4();
    await prefs.setString(_key, generated);
    _cached = generated;
    return generated;
  }
}
