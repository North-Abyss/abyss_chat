import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
