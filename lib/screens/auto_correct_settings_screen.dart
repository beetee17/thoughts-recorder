import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/utils/persistence.dart';
import 'package:settings_ui/settings_ui.dart';

import '../redux_/rootStore.dart';

class AutoCorrectPhraseRow extends StatelessWidget {
  final TextEditingController target;
  const AutoCorrectPhraseRow({Key? key, required this.target})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      style: TextStyle(color: focusedTextColor),
      controller: target,
      decoration: BoxDecoration(),
      clearButtonMode: OverlayVisibilityMode.always,
      autocorrect: false,
      onSubmitted: (newTarget) {},
    );
  }
}

class AutoCorrectPhrase extends StatelessWidget {
  final String phrase;
  final List<String> targets;

  const AutoCorrectPhrase(
      {Key? key, required this.phrase, required this.targets})
      : super(key: key);

  List<SettingsTile> mapTargetsToTiles(List<String> targets) {
    return targets.map((target) => SettingsTile(title: Text(target))).toList();
  }

  @override
  Widget build(BuildContext context) {
    print(targets);
    return StoreConnector<AppState, AutoCorrectSettingsScreenVM>(
        distinct: true,
        converter: (store) =>
            AutoCorrectSettingsScreenVM(store.state.transcriber.suggestions),
        builder: (ctx, viewModel) {
          return Scaffold(
            appBar: AppBar(title: Text(phrase)),
            body: Container(
              child: SettingsList(
                sections: [
                  SettingsSection(
                    title: Text('Set Up'),
                    tiles: [
                      ...mapTargetsToTiles(targets),
                      SettingsTile(
                          title: CupertinoTextField(
                        prefix: Icon(
                          Icons.add_circle_sharp,
                          color: CupertinoColors.activeGreen,
                        ),
                        placeholder: "Suggestion...",
                        style: TextStyle(color: focusedTextColor),
                        controller: TextEditingController(text: ""),
                        decoration: BoxDecoration(),
                        clearButtonMode: OverlayVisibilityMode.always,
                        autocorrect: false,
                        onSubmitted: (newTarget) async {
                          if (newTarget.trim().isNotEmpty) {
                            print(
                                "SUBMIT TARGET $newTarget FOR PHRASE $phrase");

                            final newSuggestions =
                                viewModel.suggestions.modify((map) {
                              final newTargets = map[phrase];
                              if (newTargets != null) {
                                newTargets.add(newTarget);
                                map[phrase] = newTargets;
                              }
                              return map;
                            });
                            await store.dispatch(
                                modifyAutoCorrectSuggestions(newSuggestions));
                          }
                        },
                      ))
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class AutoCorrectSettingsScreen extends StatelessWidget {
  final Map<String, Set<String>> suggestions;

  const AutoCorrectSettingsScreen({Key? key, required this.suggestions})
      : super(key: key);

  Text UNEDITABLE_TEXT(String content) {
    return Text(
      content,
      style: TextStyle(color: Color.fromRGBO(142, 142, 147, 1)),
    );
  }

  List<SettingsTile> mapSuggestionsToTiles(AutoCorrectSuggestions suggestions) {
    final Map<String, List<String>> suggestionsMap = suggestions.map;
    List<SettingsTile> tiles = [];

    suggestionsMap.forEach((phrase, targets) {
      tiles.add(SettingsTile(
        title: Text(phrase),
        trailing: Icon(Icons.arrow_forward_ios_rounded),
        onPressed: (ctx) {
          Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (context) => AutoCorrectPhrase(
                      phrase: phrase, targets: targets.toList())));
        },
      ));
    });
    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AutoCorrectSettingsScreenVM>(
        distinct: true,
        converter: (store) =>
            AutoCorrectSettingsScreenVM(store.state.transcriber.suggestions),
        builder: (ctx, viewModel) {
          print("BUILD");
          return Scaffold(
            appBar: AppBar(title: const Text('Auto Correct')),
            body: Container(
              child: SettingsList(
                sections: [
                  SettingsSection(
                    title: Text('Set Up'),
                    tiles: [
                      ...mapSuggestionsToTiles(viewModel.suggestions),
                      SettingsTile(
                          title: CupertinoTextField(
                        style: TextStyle(color: focusedTextColor),
                        prefix: Icon(
                          Icons.add_circle_sharp,
                          color: CupertinoColors.activeGreen,
                        ),
                        placeholder: "Phrase...",
                        controller: TextEditingController(text: ""),
                        decoration: BoxDecoration(),
                        clearButtonMode: OverlayVisibilityMode.always,
                        autocorrect: false,
                        onSubmitted: (newPhrase) async {
                          if (newPhrase.trim().isNotEmpty) {
                            print("SUBMIT PHRASE $newPhrase");
                            final newSuggestions =
                                viewModel.suggestions.modify((map) {
                              final map_ = map;
                              map_.putIfAbsent(newPhrase, () => []);
                              return map_;
                            });

                            await store.dispatch(
                                modifyAutoCorrectSuggestions(newSuggestions));
                          }
                        },
                      ))
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class AutoCorrectSettingsScreenVM {
  final AutoCorrectSuggestions suggestions;

  AutoCorrectSettingsScreenVM(this.suggestions);

  @override
  bool operator ==(other) {
    return (other is AutoCorrectSettingsScreenVM) &&
        (suggestions == other.suggestions);
  }

  @override
  int get hashCode {
    return suggestions.hashCode;
  }
}
