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
  final PageController pageController;
  const TextArea({Key? key, required this.pageController}) : super(key: key);

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
                    child: PageView(
                      controller: widget.pageController,
                      onPageChanged: (pageNumber) {
                        store.dispatch(ToggleMinutesViewAction());
                      },
                      children: [RawTextList(), FormattedTextView()],
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
          ]),
        );
      },
    );
  }
}

class TextAreaVM {
  File? file;
  bool showMinutes;
  int get pageNumber => showMinutes ? 0 : 1;

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
