import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  static Future<AutoCorrectSuggestions> getAutoCorrectSuggestionsMap() async {
    final String? jsonString =
        (await Persistence.prefs).getString('AUTOCORRECT_SUGGESTIONS_MAP');
    print("LOADED USER SUGGESTIONS: $jsonString");
    if (jsonString == null) {
      return AutoCorrectSuggestions.empty();
    }
    return AutoCorrectSuggestions.fromJson(jsonDecode(jsonString));
  }

  static Future<bool> setAutoCorrectSuggestionsMap(
      AutoCorrectSuggestions newSuggestions) async {
    final String jsonString = jsonEncode(newSuggestions);
    print("SETTING \n$jsonString");

    final result = (await Persistence.prefs)
        .setString('AUTOCORRECT_SUGGESTIONS_MAP', jsonString);

    return result;
  }
}

class AutoCorrectSuggestions {
  late final Map<String, List<String>> _map;

  AutoCorrectSuggestions({required map}) {
    _map = map;
  }

  static Future<AutoCorrectSuggestions> fromJson(
      Map<String, dynamic> parsedJson) async {
    Map<String, dynamic> theMap = parsedJson['map'];

    final Map<String, List<String>> map = theMap.map(((key, value) =>
        MapEntry(key, (value as List).whereType<String>().toList())));

    return AutoCorrectSuggestions(map: map);
  }

  List<String> getTargets(String phrase) {
    return _map[phrase] ?? [];
  }

  String? checkText(String text) {
    for (final entry in _map.entries) {
      final phrase = entry.key;
      if (text.contains(phrase)) {
        return phrase;
      }
    }
    return null;
  }

  AutoCorrectSuggestions modify(
      Map<String, List<String>> Function(Map<String, List<String>>) mapper) {
    Map<String, List<String>> newMap = mapper(_map);
    return AutoCorrectSuggestions(map: newMap);
  }

  Map<String, dynamic> toJson() {
    return {"map": _map};
  }

  Map<String, List<String>> get map => _map;

  static AutoCorrectSuggestions empty() {
    return AutoCorrectSuggestions(map: Map<String, List<String>>());
  }

  @override
  bool operator ==(other) {
    if (other is! AutoCorrectSuggestions) {
      return false;
    }
    final otherMap = other.map;

    if (map.entries.length != otherMap.entries.length ||
        map.values.length != otherMap.values.length) {
      return false;
    }

    for (final entry in map.entries) {
      final phrase = entry.key;
      final targets = entry.value;
      final otherTargets = otherMap[phrase];
      if (otherTargets == null || !listEquals(targets, otherTargets)) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    return map.hashCode;
  }
}
