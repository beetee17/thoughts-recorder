import 'package:shared_preferences/shared_preferences.dart';

class Persistence {
  static final Future<SharedPreferences> prefs =
      SharedPreferences.getInstance();
}

class Settings {
  static Future<String> getAccessKey() async {
    return (await Persistence.prefs).getString('ACCESS_KEY') ?? '';
  }

  static Future<bool> setAccessKey(String newKey) async {
    return (await Persistence.prefs).setString('ACCESS_KEY', newKey);
  }
}
