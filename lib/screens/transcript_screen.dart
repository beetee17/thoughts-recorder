import 'dart:io';
import 'dart:ui';

import 'package:Minutes/utils/colors.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/spinner.dart';
import 'package:Minutes/utils/save_file_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_redux_dev_tools/flutter_redux_dev_tools.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/error_message.dart';
import 'package:Minutes/widgets/selected_file.dart';
import 'package:Minutes/widgets/status_area.dart';
import 'package:Minutes/widgets/text_area.dart';

import '../utils/save_file_contents.dart';
import '../utils/transcript_pair.dart';
import '../widgets/text_view_segmented_control.dart';
//Import the font package

class TranscriptScreen extends StatefulWidget {
  final SaveFileContents? transcript;

  const TranscriptScreen({Key? key, this.transcript}) : super(key: key);

  @override
  _TranscriptScreenState createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Only honored in Android M and above
      statusBarIconBrightness:
          Brightness.dark, // Only honored in Android M and above
      statusBarBrightness: Brightness.light, // Only honored in iOS
    ));
    return StoreConnector<AppState, TranscriptScreenVM>(
        distinct: true,
        converter: (store) => TranscriptScreenVM(
            store.state.audio.file,
            store.state.transcript.transcriptText,
            store.state.transcript.transcriptTextList,
            store.state.status.errorMessage,
            store.state.ui.showMinutes),
        builder: (ctx, viewModel) {
          // TODO: Move to own widget so that it does not rebuild during transcription process
          final TextEditingController filenameEditingController =
              TextEditingController(
                  text: widget.transcript?.audio.nameWithoutExtension ??
                      viewModel.file?.nameWithoutExtension);
          PageController pageController =
              PageController(initialPage: viewModel.groupvalue);

          return GestureDetector(
            onTap: () =>
                SystemChannels.textInput.invokeMethod('TextInput.hide'),
            child: Scaffold(
              appBar: AppBar(
                  title: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          height: 40.0,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300.withOpacity(0.5)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Center(
                              child: CupertinoTextField(
                                controller: filenameEditingController,
                                placeholder: 'Untitled',
                                placeholderStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: unfocusedTextColor),
                                decoration:
                                    BoxDecoration(color: Colors.transparent),
                                clearButtonMode: OverlayVisibilityMode.editing,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: almostWhite,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      )),
                  actions: viewModel.file != null
                      ? [
                          IconButton(
                              onPressed: () => showSpinnerUntil(
                                  ctx,
                                  () => SaveFileHandler.save(
                                      ctx,
                                      SaveFileContents(
                                          viewModel.file!,
                                          store.state.transcript
                                              .transcriptTextList,
                                          DateTime.now()),
                                      filenameEditingController.text)),
                              icon: Icon(CupertinoIcons.doc))
                        ]
                      : [],
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.of(ctx).pop(),
                  )),
              resizeToAvoidBottomInset: false,
              body: Column(
                children: [
                  viewModel.errorMessage == null
                      ? TextArea(pageController: pageController)
                      : ErrorMessage(errorMessage: viewModel.errorMessage!),
                  Container(
                    padding: EdgeInsets.only(top: 20, bottom: 30),
                    decoration: BoxDecoration(
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            spreadRadius: 1,
                            offset: Offset(0, -3))
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: TextViewSegmentedControl(
                              onChange: (groupvalue) =>
                                  pageController.animateToPage(groupvalue,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut)),
                        ),
                        StatusArea(),
                        SizedBox(height: 10),
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
        });
  }
}

class TranscriptScreenVM {
  File? file;
  String transcriptText;
  List<TranscriptPair> transcriptTextList;
  String? errorMessage;
  bool showMinutes;
  int get groupvalue => showMinutes ? 0 : 1;
  TranscriptScreenVM(this.file, this.transcriptText, this.transcriptTextList,
      this.errorMessage, this.showMinutes);

  @override
  bool operator ==(other) {
    return (other is TranscriptScreenVM) &&
        (file == other.file) &&
        (transcriptText == other.transcriptText) &&
        (transcriptTextList == other.transcriptTextList) &&
        (errorMessage == other.errorMessage) &&
        (showMinutes == other.showMinutes);
  }

  @override
  int get hashCode {
    return Object.hash(
        file, transcriptText, transcriptTextList, errorMessage, showMinutes);
  }
}
