import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/utils/colors.dart';
import 'package:Minutes/utils/text_field_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Minutes/utils/extensions.dart';

import '../redux_/rootStore.dart';
import '../utils/transcript_pair.dart';
import 'just_audio_player.dart';

class DefaultSpan extends StatefulWidget {
  final int wordIndex;
  DefaultSpan({Key? key, required this.wordIndex}) : super(key: key);

  @override
  State<DefaultSpan> createState() => _DefaultSpanState();
}

class _DefaultSpanState extends State<DefaultSpan> {
  Offset _tapPosition = Offset.zero;
  bool _isHighlighted = false;

  void _showCustomMenu(String content) async {
    final RenderObject? overlay =
        Overlay.of(context)?.context.findRenderObject();
    if (overlay == null) {
      return;
    }

    setState(() {
      _isHighlighted = true;
    });

    final editResponse = await showMenu(
        color: accentColor,
        constraints: BoxConstraints.loose(Size(350, 50)),
        context: context,
        items: <PopupMenuEntry<EditResponse>>[EditMenuEntry(content)],
        position: RelativeRect.fromRect(
            _tapPosition & const Size(40, 40), // smaller rect, the touch area
            Offset(-80, 75) &
                overlay.semanticBounds.size // Bigger rect, the entire screen
            ));
    // This is how you handle user selection
    setState(() {
      _isHighlighted = false;
    });
    if (editResponse == null) {
      return;
    }
    switch (editResponse.command) {
      case EditCommand.Add:
        store.dispatch(
            AddTextAfterWordAction(editResponse.payload, widget.wordIndex));
        break;
      case EditCommand.Delete:
        store.dispatch(DeleteWordAction(widget.wordIndex));
        break;
      case EditCommand.Edit:
        store.dispatch(EditWordAction(editResponse.payload, widget.wordIndex));
        break;
    }
  }

  void _storePosition(TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, DefaultSpanVM>(
        distinct: true,
        converter: (store) => DefaultSpanVM(
            store.state.transcript.highlightSpan,
            store.state.transcript.highlightedParent,
            store.state.transcript.transcriptTextList[widget.wordIndex],
            store.state.audio.duration),
        builder: (_, viewModel) {
          final String punctuated = viewModel.pair.punctuated.trim();
          final String original = viewModel.pair.word.trim();

          void onTapSpan() {
            print("Text: ${viewModel.pair} tapped");
            final Duration seekTime = DurationUtils.min(
                viewModel.audioDuration, viewModel.pair.startTime);
            print('seeking: ${seekTime.inSeconds}s');
            JustAudioPlayerWidgetState.player.seek(seekTime);
          }

          TextStyle getStyle() {
            TextStyle res = TextStyle();
            if (viewModel.highlightedParent == viewModel.pair.parent) {
              res = TextStyle(color: focusedTextColor);
            } else {
              res = TextStyle(color: Colors.white60);
            }

            if (_isHighlighted) {
              res = TextStyle(
                  color: focusedTextColor,
                  decoration: TextDecoration.underline);
            }
            if (viewModel.pair.punctuationData != null &&
                punctuated != original) {
              res = TextStyle(
                  color: Color.lerp(
                      CupertinoColors.destructiveRed,
                      CupertinoColors.activeGreen.darkHighContrastColor,
                      viewModel.pair.punctuationData!.second));
            }
            return res;
          }

          print('$punctuated & $original');
          return AnimatedDefaultTextStyle(
            child: punctuated != original
                ? GestureDetector(
                    child: Text('$punctuated '),
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        details.primaryVelocity! < 0
                            ? store.dispatch(
                                acceptPunctuatorSuggestion(widget.wordIndex))
                            : store.dispatch(
                                rejectPunctuatorSuggestion(widget.wordIndex));
                      }
                    },
                  )
                : GestureDetector(
                    child: Text('$original '),
                    onLongPress: () => _showCustomMenu(viewModel.pair.word),
                    onTapDown: _storePosition,
                    onTap: onTapSpan,
                  ),
            style: GoogleFonts.rubik(
                    fontSize: 24, fontWeight: FontWeight.w500, height: 1.4)
                .merge(getStyle()),
            duration: Duration(milliseconds: 300),
          );
        });
  }
}

class EditMenuEntry extends PopupMenuEntry<EditResponse> {
  final String word;

  EditMenuEntry(this.word);

  // height doesn't matter, as long as we are not giving
  // initialValue to showMenu().
  @override
  double height = 20;

  @override
  bool represents(EditResponse? s) => true;

  @override
  EditMenuEntryState createState() => EditMenuEntryState();
}

class EditMenuEntryState extends State<EditMenuEntry> {
  Widget AddMenuItem(String displayText, String payload) {
    return TextButton(
      onPressed: () => Navigator.pop<EditResponse>(
          context, EditResponse(EditCommand.Add, payload)),
      child: Text(
        displayText,
        style:
            TextStyle(fontSize: 24, color: Color.fromARGB(255, 137, 206, 78)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
              onPressed: () => Navigator.pop<EditResponse>(
                  context, EditResponse(EditCommand.Delete, '##IGNORE##')),
              icon: Icon(CupertinoIcons.trash),
              color: Colors.redAccent),
          IconButton(
              onPressed: () {
                showTextInputDialog(
                    context,
                    Text('Quick Edit'),
                    widget.word,
                    (newWord) => Navigator.pop<EditResponse>(
                        context, EditResponse(EditCommand.Edit, newWord)));
              },
              icon: Icon(Icons.edit),
              color: CupertinoColors.activeBlue),
          IconButton(
              onPressed: () => Navigator.pop<EditResponse>(
                  context,
                  EditResponse(
                      EditCommand.Edit, widget.word.toggleCapitalisation())),
              icon: Icon(CupertinoIcons.textformat),
              color: CupertinoColors.activeBlue),
          AddMenuItem('.', '.'),
          AddMenuItem(',', ','),
          AddMenuItem(r'\n', '\n'),
        ],
      ),
    );
  }
}

enum EditCommand { Add, Edit, Delete }

class EditResponse {
  EditCommand command;
  String payload;
  EditResponse(this.command, this.payload);
}

class DefaultSpanVM {
  void Function(String) highlightParent;
  String? highlightedParent;
  TranscriptPair pair;
  Duration audioDuration;
  DefaultSpanVM(this.highlightParent, this.highlightedParent, this.pair,
      this.audioDuration);
  @override
  bool operator ==(other) {
    return (other is DefaultSpanVM) &&
        (highlightParent == other.highlightParent) &&
        (highlightedParent == other.highlightedParent) &&
        (pair == other.pair) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(highlightParent, highlightedParent, pair, audioDuration);
  }
}
