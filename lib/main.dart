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
import 'package:leopard_demo/screens/settings_screen.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/utils/global_variables.dart';
import 'package:leopard_demo/utils/pair.dart';
import 'package:leopard_demo/utils/persistence.dart';
import 'package:leopard_demo/widgets/error_message.dart';
import 'package:leopard_demo/widgets/selected_file.dart';
import 'package:leopard_demo/widgets/status_area.dart';
import 'package:leopard_demo/widgets/text_area.dart';
//Import the font package
import 'package:google_fonts/google_fonts.dart';
import 'package:leopard_demo/widgets/tutorial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
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
              foregroundColor: Colors.black //here you can give the text color
              ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              )),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    Settings.setAccessKey(debugAccessKey).then((bool success) {
      store.dispatch(UntitledState.initLeopard);
    });
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
      child: StoreConnector<AppState, HomeVM>(
          distinct: true,
          converter: (store) => HomeVM(
              store.state.untitled.transcriptText,
              store.state.untitled.transcriptTextList,
              store.state.untitled.errorMessage),
          builder: (_, viewModel) {
            final TextEditingController textEditingController =
                TextEditingController(text: viewModel.transcriptText);
            return GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                TextFormatter.updateTranscriptTextList(
                    textEditingController.text, viewModel.transcriptTextList);
              },
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Transcript'),
                  leading: IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Scaffold(
                                  appBar: AppBar(title: Text("Tutorial")),
                                  body: Tutorial())));
                    },
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsScreen()));
                      },
                    )
                  ],
                ),
                resizeToAvoidBottomInset: false,
                body: Column(
                  children: [
                    viewModel.errorMessage == null
                        ? TextArea(textEditingController: textEditingController)
                        : ErrorMessage(errorMessage: viewModel.errorMessage!),
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
                    )),
              ),
            );
          }),
    );
  }
}

class HomeVM {
  String transcriptText;
  List<Pair<String, double>> transcriptTextList;
  String? errorMessage;
  HomeVM(this.transcriptText, this.transcriptTextList, this.errorMessage);

  @override
  bool operator ==(other) {
    return (other is HomeVM) &&
        (transcriptText == other.transcriptText) &&
        (transcriptTextList == other.transcriptTextList) &&
        (errorMessage == other.errorMessage);
  }

  @override
  int get hashCode {
    return Object.hash(transcriptText, transcriptTextList, errorMessage);
  }
}
