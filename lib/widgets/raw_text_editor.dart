import 'package:Minutes/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/widgets/just_audio_player.dart';

import '../redux_/transcript.dart';
import '../utils/transcript_pair.dart';

class RawTextEditor extends StatefulWidget {
  final int index;
  final TranscriptPair partialTranscript;
  const RawTextEditor(
      {Key? key, required this.partialTranscript, required this.index})
      : super(key: key);

  @override
  State<RawTextEditor> createState() => _RawTextEditorState();
}

class _RawTextEditorState extends State<RawTextEditor> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: widget.partialTranscript.text);
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RawTextFieldVM>(
        distinct: true,
        converter: (store) => RawTextFieldVM(
            store.state.transcript.highlightedSpanIndex,
            store.state.audio.duration),
        builder: (_, viewModel) {
          TextStyle shouldHighlightSpan() {
            if (viewModel.highlightedSpanIndex == widget.index) {
              return TextStyle(
                  color: focusedTextColor, fontWeight: FontWeight.bold);
            }
            return TextStyle(color: unfocusedTextColor);
          }

          return Container(
            child: TextField(
                onChanged: (updatedText) {
                  store.dispatch(UpdateTranscriptTextList(
                      widget.index,
                      TranscriptPair(
                          updatedText, widget.partialTranscript.startTime)));
                },
                maxLines: null,
                style: shouldHighlightSpan(),
                decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30)),
                    prefix: GestureDetector(
                        child: Text(
                            '${widget.partialTranscript.startTime.toAudioDurationString()} ',
                            style: TextStyle(
                                color: Color.fromARGB(153, 108, 108, 121),
                                fontWeight: FontWeight.normal)),
                        onTap: () {
                          final Duration seekTime = DurationUtils.min(
                              viewModel.audioDuration,
                              widget.partialTranscript.startTime);
                          print('seeking: ${seekTime.inSeconds}s');
                          JustAudioPlayerWidgetState.player.seek(seekTime);
                        })),
                controller: _textEditingController),
          );
        });
  }
}

class RawTextFieldVM {
  int? highlightedSpanIndex;
  Duration audioDuration;

  RawTextFieldVM(this.highlightedSpanIndex, this.audioDuration);

  @override
  bool operator ==(other) {
    return (other is RawTextFieldVM) &&
        (highlightedSpanIndex == other.highlightedSpanIndex) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(highlightedSpanIndex, audioDuration);
  }
}
