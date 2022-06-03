import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Text UNEDITABLE_TEXT(String content) {
    return Text(
      content,
      style: TextStyle(color: Color.fromRGBO(142, 142, 147, 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      controller: TextEditingController(text: 'Hello'),
                      decoration: InputDecoration.collapsed(hintText: ''),
                      textAlign: TextAlign.end,
                      autocorrect: false,
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
                    style: TextStyle(color: Color.fromRGBO(142, 142, 147, 1)),
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
          ],
        ),
      ),
    );
  }
}
