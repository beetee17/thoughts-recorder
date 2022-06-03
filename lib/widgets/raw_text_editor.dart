import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/widgets/just_audio_player.dart';

import '../utils/pair.dart';

class RawTextEditor extends StatefulWidget {
  final int index;
  final Pair<String, Duration> partialTranscript;
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
        TextEditingController(text: widget.partialTranscript.first);
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RawTextFieldVM>(
        converter: (store) => RawTextFieldVM(
            store.state.untitled.highlightedSpanIndex,
            store.state.untitled.audioDuration),
        builder: (_, viewModel) {
          TextStyle shouldHighlightSpan() {
            if (viewModel.highlightedSpanIndex == widget.index) {
              return TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold);
            }
            return TextStyle(color: Color.fromARGB(205, 0, 0, 0));
          }

          return Container(
            padding: EdgeInsets.symmetric(vertical: 0),
            child: TextField(
                onChanged: (updatedText) {
                  store.dispatch(UpdateTranscriptTextList(widget.index,
                      Pair(updatedText, widget.partialTranscript.second)));
                },
                maxLines: null,
                style: shouldHighlightSpan(),
                decoration: InputDecoration(
                    prefix: GestureDetector(
                        child: Text(
                            '${widget.partialTranscript.second.toAudioDurationString()} ',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.normal)),
                        onTap: () {
                          final Duration seekTime = DurationUtils.min(
                              viewModel.audioDuration,
                              widget.partialTranscript.second);
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
