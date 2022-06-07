import 'package:Minutes/screens/files_screen.dart';
import 'package:Minutes/utils/transcriptClasses.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_redux_dev_tools/flutter_redux_dev_tools.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/screens/settings_screen.dart';
import 'package:Minutes/utils/persistence.dart';
import 'package:Minutes/widgets/error_message.dart';
import 'package:Minutes/widgets/selected_file.dart';
import 'package:Minutes/widgets/status_area.dart';
import 'package:Minutes/widgets/text_area.dart';
//Import the font package
import 'package:Minutes/widgets/tutorial.dart';

class TranscriptScreen extends StatefulWidget {
  @override
  _TranscriptScreenState createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  @override
  void initState() {
    super.initState();
    Settings.getAccessKey().then((value) {
      showDialog(
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
        context: context,
      );
      InitLeopardAction()
          .call(store)
          .then((value) => Navigator.of(context).pop());
    });
  }

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
      child: StoreConnector<AppState, TranscriptScreenVM>(
          distinct: true,
          converter: (store) => TranscriptScreenVM(
              store.state.transcript.transcriptText,
              store.state.transcript.transcriptTextList,
              store.state.status.errorMessage),
          builder: (_, viewModel) {
            final TextEditingController textEditingController =
                TextEditingController(text: viewModel.transcriptText);
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Scaffold(
                appBar: AppBar(
                    title: const Text('Transcript'),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.of(context).pop(),
                    )),
                resizeToAvoidBottomInset: false,
                body: Column(
                  children: [
                    viewModel.errorMessage == null
                        ? TextArea()
                        : ErrorMessage(errorMessage: viewModel.errorMessage!),
                    Container(
                      padding: EdgeInsets.only(top: 20, bottom: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
          }),
    );
  }
}

class TranscriptScreenVM {
  String transcriptText;
  List<TranscriptPair> transcriptTextList;
  String? errorMessage;
  TranscriptScreenVM(
      this.transcriptText, this.transcriptTextList, this.errorMessage);

  @override
  bool operator ==(other) {
    return (other is TranscriptScreenVM) &&
        (transcriptText == other.transcriptText) &&
        (transcriptTextList == other.transcriptTextList) &&
        (errorMessage == other.errorMessage);
  }

  @override
  int get hashCode {
    return Object.hash(transcriptText, transcriptTextList, errorMessage);
  }
}