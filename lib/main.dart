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
import 'package:leopard_demo/utils/pair.dart';
import 'package:leopard_demo/widgets/selected_file.dart';
import 'package:leopard_demo/widgets/status_area.dart';
import 'package:leopard_demo/widgets/text_area.dart';
//Import the font package
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
          distinct: true,
          converter: (store) => MyAppOuterVM(
              store.state.untitled.transcriptText,
              store.state.untitled.transcriptTextList),
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
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: AppBarTheme(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          Colors.black //here you can give the text color
                      ),
                  textTheme: Theme.of(context).textTheme.apply(
                        bodyColor: Colors.black,
                        displayColor: Colors.black,
                      )),
              home: GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  TextFormatter.updateTranscriptTextList(
                      textEditingController.text, viewModel.transcriptTextList);
                },
                child: Scaffold(
                    appBar: AppBar(title: const Text('Transcript')),
                    resizeToAvoidBottomInset: false,
                    body: Column(
                      children: [
                        TextArea(textEditingController: textEditingController),
                        // ErrorMessage(),
                        Container(
                          padding: EdgeInsets.only(top: 20, bottom: 30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1), //New
                                  blurRadius: 1,
                                  spreadRadius: 1,
                                  offset: Offset(0, -3))
                            ],
                          ),
                          child: Column(
                            children: [
                              StatusArea(),
                              SelectedFile(),
                            ],
                          ),
                        ),
                      ],
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
  List<Pair<String, double>> transcriptTextList;
  MyAppOuterVM(this.transcriptText, this.transcriptTextList);

  @override
  bool operator ==(other) {
    return (other is MyAppOuterVM) &&
        (transcriptText == other.transcriptText) &&
        (transcriptTextList == other.transcriptTextList);
  }

  @override
  int get hashCode {
    return Object.hash(transcriptText.hashCode, transcriptTextList.hashCode);
  }
}
