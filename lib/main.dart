//
// Copyright 2022 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_redux_dev_tools/flutter_redux_dev_tools.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/widgets/save_audio_button.dart';
import 'package:leopard_demo/widgets/selected_file.dart';
import 'package:leopard_demo/widgets/start_recording_button.dart';
import 'package:leopard_demo/widgets/status_area.dart';
import 'package:leopard_demo/widgets/text_area.dart';
import 'package:leopard_demo/widgets/transcribe_audio_file_button.dart';
import 'package:leopard_demo/widgets/upload_file_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    store.dispatch(UntitledState.initLeopard);
  }

  Color picoBlue = Color.fromRGBO(55, 125, 255, 1);
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Only honored in Android M and above
      statusBarIconBrightness:
          Brightness.dark, // Only honored in Android M and above
      statusBarBrightness: Brightness.light, // Only honored in iOS
    ));
    return StoreProvider<AppState>(
      store: store,
      child: StoreConnector<AppState, MyAppOuterVM>(
          converter: (store) => MyAppOuterVM(
              store.state.untitled.transcriptText, store.state.untitled.file),
          builder: (_, viewModel) {
            final TextEditingController textEditingController =
                TextEditingController(text: viewModel.transcriptText);
            return MaterialApp(
              // debugShowCheckedModeBanner: false,
              theme: ThemeData(
                  sliderTheme: SliderThemeData(
                    trackHeight: 5,
                    thumbColor: Colors.blue.shade800,
                    activeTrackColor: Colors.blue.shade800,
                    thumbShape: RoundSliderThumbShape(elevation: 3),
                    valueIndicatorColor: Colors.black87,
                    overlayColor: Colors.grey.withOpacity(0.2),
                    // inactiveTrackColor: Colors.green,
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: AppBarTheme(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          Colors.black //here you can give the text color
                      ),
                  textTheme: Theme.of(context).textTheme.apply(
                        bodyColor: Colors.black, //<-- SEE HERE
                        displayColor: Colors.black, //<-- SEE HERE
                      )),
              home: GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  TextFormatter.formatTextList(textEditingController.text,
                      store.state.untitled.transcriptTextList);
                },
                child: Scaffold(
                    appBar: AppBar(title: const Text('Transcript')),
                    resizeToAvoidBottomInset: false,
                    key: _scaffoldKey,
                    body: SafeArea(
                      child: Column(
                        children: [
                          TextArea(
                              textEditingController: textEditingController),
                          // ErrorMessage(),
                          StatusArea(),

                          SelectedFile(),
                        ],
                      ),
                    ),
                    endDrawer: Container(
                        color: Colors.white,
                        child: ReduxDevTools<AppState>(
                          store,
                          stateMaxLines: 10,
                        ))),
              ),
            );
          }),
    );
  }
}

class MyAppOuterVM {
  String transcriptText;
  File? file;
  MyAppOuterVM(this.transcriptText, this.file);
}
