import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/utils/persistence.dart';
import 'package:settings_ui/settings_ui.dart';

import '../redux_/rootStore.dart';

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
        Future.delayed(Duration.zero, () => TextEditingController(text: key)));
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
                                leading: Icon(Icons.key),
                                title: Text('Access Key'),
                                trailing: Expanded(
                                  flex: 2,
                                  child: CupertinoTextField(
                                    controller: snapshot.data,
                                    decoration: BoxDecoration(),
                                    clearButtonMode:
                                        OverlayVisibilityMode.always,
                                    autocorrect: false,
                                    onSubmitted: (newKey) {
                                      Settings.setAccessKey(newKey)
                                          .then((bool success) {
                                        showDialog(
                                          barrierDismissible: false,
                                          builder: (ctx) => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          context: context,
                                        );
                                        InitLeopardAction().call(store).then(
                                            (value) =>
                                                Navigator.of(context).pop());
                                      });
                                    },
                                  ),
                                ),
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
                          )
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
