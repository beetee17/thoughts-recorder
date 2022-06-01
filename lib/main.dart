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
import 'package:leopard_demo/widgets/save_audio_button.dart';
import 'package:leopard_demo/widgets/selected_file.dart';
import 'package:leopard_demo/widgets/start_recording_button.dart';
import 'package:leopard_demo/widgets/status_area.dart';
import 'package:leopard_demo/widgets/text_area.dart';
import 'package:leopard_demo/widgets/transcribe_audio_file_button.dart';
import 'package:leopard_demo/widgets/upload_file_button.dart';

void main() {
  runApp(MyApp());
  // runApp(MultiProvider(
  //   providers: [
  //     ChangeNotifierProvider(create: (_) => MainProvider()),
  //     ChangeNotifierProvider(create: (_) => AudioProvider()),
  //   ],
  //   child: MyApp(),
  // ));
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
    return StoreProvider<AppState>(
      store: store,
      child: StoreConnector<AppState, MyAppOuterVM>(
          converter: (store) => MyAppOuterVM(
              store.state.untitled.transcriptText, store.state.untitled.file),
          builder: (_, viewModel) {
            return MaterialApp(
              home: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    key: _scaffoldKey,
                    appBar: AppBar(
                      title: const Text('Thoughts Recorder'),
                      backgroundColor: picoBlue,
                    ),
                    body: Column(
                      children: [
                        TextArea(
                            textEditingController: TextEditingController(
                                text: viewModel.transcriptText)),
                        // ErrorMessage(),
                        StatusArea(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            viewModel.file == null
                                ? StartRecordingButton()
                                : TranscribeAudioFileButton(),
                            UploadFileButton(),
                            SaveAudioButton()
                          ],
                        ),
                        SelectedFile(),
                        SizedBox(
                          height: 30,
                        )
                      ],
                    ),
                    endDrawer: Container(
                        color: Colors.white60,
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
