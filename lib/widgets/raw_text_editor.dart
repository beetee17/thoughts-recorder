import 'package:Minutes/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/widgets/just_audio_player.dart';

import '../redux_/transcript.dart';
import '../utils/pair.dart';
import '../utils/transcript_pair.dart';

class RawTextEditor extends StatefulWidget {
  final Pair<String, Duration> data;
  final String minutes;
  const RawTextEditor({Key? key, required this.minutes, required this.data})
      : super(key: key);

  @override
  State<RawTextEditor> createState() => _RawTextEditorState();
}

class _RawTextEditorState extends State<RawTextEditor> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.minutes);
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
            store.state.transcript.highlightedParent,
            store.state.audio.duration),
        builder: (_, viewModel) {
          TextStyle getStyle() {
            if (viewModel.highlightedParent == widget.data.first) {
              return TextStyle(
                  color: focusedTextColor, fontWeight: FontWeight.bold);
            }
            return TextStyle(color: unfocusedTextColor);
          }

          return Container(
            child: TextField(
                onChanged: (updatedText) {
                  // This is probably quite inefficient to perform everytime text changes
                  // Time complexity depends on the size of transcriptTextList
                  store.dispatch(
                      UpdateTranscriptTextList(widget.data.first, updatedText));
                },
                maxLines: null,
                style: getStyle(),
                decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30)),
                    prefix: GestureDetector(
                        child: Text(
                            '${widget.data.second.toAudioDurationString()} ',
                            style: TextStyle(
                                color: Color.fromARGB(153, 108, 108, 121),
                                fontWeight: FontWeight.normal)),
                        onTap: () {
                          final Duration seekTime = DurationUtils.min(
                              viewModel.audioDuration, widget.data.second);
                          print('seeking: ${seekTime.inSeconds}s');
                          JustAudioPlayerWidgetState.player.seek(seekTime);
                        })),
                controller: _textEditingController),
          );
        });
  }
}

class RawTextFieldVM {
  String highlightedParent;
  Duration audioDuration;

  RawTextFieldVM(this.highlightedParent, this.audioDuration);

  @override
  bool operator ==(other) {
    return (other is RawTextFieldVM) &&
        (highlightedParent == other.highlightedParent) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(highlightedParent, audioDuration);
  }
}
