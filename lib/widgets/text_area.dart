import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/raw_text_list.dart';
import 'package:Minutes/widgets/save_transcript_button.dart';
import 'package:Minutes/widgets/secondary_icon_button.dart';

import 'formatted_text.dart';

class TextArea extends StatefulWidget {
  const TextArea({Key? key}) : super(key: key);

  @override
  State<TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<TextArea> {
  bool showRawText = false;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, TextAreaVM>(
      converter: (store) => TextAreaVM(store.state.audio.file),
      distinct: true,
      builder: (_, viewModel) {
        return Expanded(
          child: Stack(children: [
            Container(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom / 2),
                child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: showRawText ? RawTextList() : FormattedTextView(),
                    )),
              ),
            ),
            Container(
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SaveTranscriptButton(),
                  SizedBox(
                    height: 20,
                  ),
                  SecondaryIconButton(
                      onPress: () {
                        setState(() {
                          showRawText = !showRawText;
                        });
                      },
                      margin: EdgeInsets.only(bottom: 10.0, right: 10.0),
                      icon:
                          Icon(showRawText ? CupertinoIcons.eye : Icons.edit)),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

class TextAreaVM {
  File? file;
  TextAreaVM(this.file);
  @override
  bool operator ==(other) {
    return (other is TextAreaVM) && (file == other.file);
  }

  @override
  int get hashCode {
    return file.hashCode;
  }
}
