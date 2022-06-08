import 'dart:io';

import 'package:Minutes/redux_/ui.dart';
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
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, TextAreaVM>(
      distinct: true,
      converter: (store) =>
          TextAreaVM(store.state.audio.file, store.state.ui.showMinutes),
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
                      child: viewModel.showMinutes
                          ? RawTextList()
                          : FormattedTextView(),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: SaveTranscriptButton(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CupertinoSlidingSegmentedControl(
                  children: {0: Text('Minutes'), 1: Text('Preview')},
                  onValueChanged: (newValue) {
                    store.dispatch(ToggleMinutesViewAction());
                  },
                  groupValue: viewModel.groupvalue,
                ),
              ),
            )
          ]),
        );
      },
    );
  }
}

class TextAreaVM {
  File? file;
  bool showMinutes;
  int? get groupvalue => showMinutes ? 0 : 1;

  TextAreaVM(this.file, this.showMinutes);
  @override
  bool operator ==(other) {
    return (other is TextAreaVM) &&
        (file == other.file) &&
        (showMinutes == other.showMinutes);
  }

  @override
  int get hashCode {
    return Object.hash(file, showMinutes);
  }
}
