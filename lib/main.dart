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

import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/providers/main_provider.dart';
import 'package:leopard_demo/utils/global_variables.dart';
import 'package:leopard_demo/widgets/error_message.dart';
import 'package:leopard_demo/widgets/share_transcript_button.dart';
import 'package:leopard_demo/widgets/selected_file.dart';
import 'package:leopard_demo/widgets/start_recording_button.dart';
import 'package:leopard_demo/widgets/status_area.dart';
import 'package:leopard_demo/widgets/text_area.dart';
import 'package:leopard_demo/widgets/upload_file_button.dart';
import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MainProvider()),
    ],
    child: MyApp(),
  ));
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
    context.read<MainProvider>().initLeopard();
  }

  Color picoBlue = Color.fromRGBO(55, 125, 255, 1);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Thoughts Recorder'),
          backgroundColor: picoBlue,
        ),
        body: Column(
          children: [
            TextArea(
                textEditingController: TextEditingController(
                    text: context.watch<MainProvider>().transcriptText)),
            // ErrorMessage(),
            StatusArea(),
            Row(
              children: [
                StartButton(),
                UploadFileButton(),
                SaveTranscriptButton()
              ],
            ),
            SelectedFile(),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }
}
