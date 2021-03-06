import 'dart:io';
import 'dart:math';

import 'package:Minutes/ffi.dart';
import 'package:Minutes/redux_/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/raw_text_list.dart';
import 'package:Minutes/widgets/save_transcript_button.dart';
import 'package:Minutes/widgets/secondary_icon_button.dart';
import 'package:leopard_flutter/leopard.dart';
import 'package:path_provider/path_provider.dart';

import '../redux_/transcript.dart';
import 'formatted_text.dart';
import 'package:path/path.dart' as path;

class TextArea extends StatefulWidget {
  final PageController pageController;
  const TextArea({Key? key, required this.pageController}) : super(key: key);

  @override
  State<TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<TextArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  );

  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(1.5, 0.0),
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticIn,
  ));

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, TextAreaVM>(
      converter: (store) =>
          TextAreaVM(store.state.audio.file, store.state.ui.showMinutes),
      builder: (ctx, viewModel) {
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryIconButton(
                      margin: EdgeInsets.only(top: 10.0, right: 10.0),
                      icon: Icon(Icons.auto_fix_high_sharp),
                      onPress: () => PunctuateTranscript().call(store),
                    ),
                    SaveTranscriptButton(),
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: MediaQuery.of(context).viewInsets.bottom < 200 ? 0 : 1,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: max(
                        0, MediaQuery.of(context).viewInsets.bottom / 2 - 50),
                    right: 10),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: MediaQuery.of(context).viewInsets.bottom == 0
                        ? SizedBox(width: 0, height: 0)
                        : FloatingActionButton(
                            backgroundColor: Color.fromRGBO(226, 230, 232, 1),
                            child: Icon(
                              CupertinoIcons.keyboard_chevron_compact_down,
                              color: CupertinoColors.systemGrey,
                              size: 30,
                            ),
                            onPressed: () => FocusScope.of(context)
                                .requestFocus(FocusNode()))),
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
