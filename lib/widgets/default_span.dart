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
  final TranscriptPair pair;
  final String text;
  final int sentenceIndex;
  final int wordIndex;
  const DefaultSpan(
      {Key? key,
      required this.text,
      required this.wordIndex,
      required this.sentenceIndex,
      required this.pair})
      : super(key: key);

  @override
  State<DefaultSpan> createState() => _DefaultSpanState();
}

class _DefaultSpanState extends State<DefaultSpan> {
  Offset _tapPosition = Offset.zero;
  bool _isHighlighted = false;

  void _showCustomMenu() async {
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
        constraints: BoxConstraints.loose(Size(300, 50)),
        context: context,
        items: <PopupMenuEntry<EditResponse>>[EditMenuEntry(widget.text)],
        position: RelativeRect.fromRect(
            _tapPosition & const Size(40, 40), // smaller rect, the touch area
            Offset(0, 80) &
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
        store.dispatch(AddTextAfterWordAction(
            editResponse.payload, widget.sentenceIndex, widget.wordIndex));
        break;
      case EditCommand.Delete:
        store
            .dispatch(DeleteWordAction(widget.sentenceIndex, widget.wordIndex));
        break;
      case EditCommand.Edit:
        store.dispatch(EditWordAction(
            editResponse.payload, widget.sentenceIndex, widget.wordIndex));
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
            store.state.transcript.highlightedSpanIndex,
            store.state.audio.duration),
        builder: (_, viewModel) {
          void onTapSpan() {
            print("Text: ${widget.pair} tapped");
            final Duration seekTime = DurationUtils.min(
                viewModel.audioDuration, widget.pair.startTime);
            print('seeking: ${seekTime.inSeconds}s');
            JustAudioPlayerWidgetState.player.seek(seekTime);
          }

          TextStyle getStyle() {
            TextStyle res = TextStyle();
            if (viewModel.highlightedSpanIndex == widget.sentenceIndex) {
              res = TextStyle(color: textColor);
            } else {
              res = TextStyle(color: unfocusedTextColor);
            }

            if (_isHighlighted) {
              res = TextStyle(
                  color: textColor, decoration: TextDecoration.underline);
            }
            return res;
          }

          return AnimatedDefaultTextStyle(
            child: GestureDetector(
              child: Text('${widget.text} '),
              onLongPress: _showCustomMenu,
              onTapDown: _storePosition,
              onTap: onTapSpan,
            ),
            style: GoogleFonts.rubik(
                    fontSize: 26, fontWeight: FontWeight.w500, height: 1.4)
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
              color: Colors.blueAccent),
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
  void Function(int) highlightSpan;
  int? highlightedSpanIndex;
  Duration audioDuration;
  DefaultSpanVM(
      this.highlightSpan, this.highlightedSpanIndex, this.audioDuration);
  @override
  bool operator ==(other) {
    return (other is DefaultSpanVM) &&
        (highlightSpan == other.highlightSpan) &&
        (highlightedSpanIndex == other.highlightedSpanIndex) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(highlightSpan, highlightedSpanIndex, audioDuration);
  }
}
