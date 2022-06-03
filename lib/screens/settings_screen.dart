import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/utils/persistence.dart';
import 'package:settings_ui/settings_ui.dart';

import '../redux_/rootStore.dart';
import '../redux_/untitled.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<TextEditingController> _accessKeyController;

  @override
  void initState() {
    super.initState();
    _accessKeyController = Settings.getAccessKey().then((key) =>
        _accessKeyController = Future.delayed(
            Duration.zero, (() => TextEditingController(text: key))));
  }

  Text UNEDITABLE_TEXT(String content) {
    return Text(
      content,
      style: TextStyle(color: Color.fromRGBO(142, 142, 147, 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextEditingController>(
        future: _accessKeyController,
        builder: (BuildContext context,
            AsyncSnapshot<TextEditingController> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const CircularProgressIndicator();

            default:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return StoreProvider(
                  store: store,
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Settings')),
                    body: Container(
                      child: SettingsList(
                        sections: [
                          SettingsSection(
                            title: Text('Set Up'),
                            tiles: <SettingsTile>[
                              SettingsTile(
                                trailing: Expanded(
                                  child: TextField(
                                    controller: snapshot.data,
                                    decoration:
                                        InputDecoration.collapsed(hintText: ''),
                                    textAlign: TextAlign.end,
                                    autocorrect: false,
                                    onSubmitted: (newKey) {
                                      print("SUBMITED $newKey");
                                      Settings.setAccessKey(newKey)
                                          .then((bool success) {
                                        store.dispatch(
                                            UntitledState.initLeopard);
                                        print(success);
                                      });
                                    },
                                  ),
                                ),
                                leading: Icon(Icons.key),
                                title: Text('Access Key'),
                              ),
                            ],
                          ),
                          SettingsSection(
                            title: Text(
                              'Key Phrases',
                            ),
                            tiles: <SettingsTile>[
                              SettingsTile(
                                title: Text(
                                  'FULL STOP',
                                ),
                                value: Text(
                                  '.',
                                  style: TextStyle(
                                      color: Color.fromRGBO(142, 142, 147, 1)),
                                ),
                              ),
                              SettingsTile(
                                title: Text('PERIOD'),
                                value: UNEDITABLE_TEXT('.'),
                              ),
                              SettingsTile(
                                title: Text('COMMA'),
                                value: UNEDITABLE_TEXT(','),
                              ),
                              SettingsTile(
                                title: Text('NEW LINE'),
                                value: UNEDITABLE_TEXT(r'\n\n'),
                              ),
                              SettingsTile(
                                title: Text('OPEN BRACKET'),
                                value: UNEDITABLE_TEXT(r'('),
                              ),
                              SettingsTile(
                                title: Text('FINISH BRACKET'),
                                value: UNEDITABLE_TEXT(r')'),
                              ),
                              SettingsTile(
                                title: Text('MAKE POINT'),
                                value: UNEDITABLE_TEXT(r'\n\n- '),
                              ),
                            ],
                          ),
                          SettingsSection(tiles: [
                            SettingsTile(
                              title: Text('Restart'),
                              trailing: IconButton(
                                  onPressed: () {
                                    store.dispatch(UntitledState.initLeopard);
                                  },
                                  icon: Icon(Icons.refresh_rounded)),
                            )
                          ])
                        ],
                      ),
                    ),
                  ),
                );
              }
          }
        });
  }
}
