import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leopard_demo/utils/extensions.dart';

import '../redux_/rootStore.dart';
import '../utils/pair.dart';
import 'just_audio_player.dart';

class FormattedTextView extends StatefulWidget {
  final String text;
  const FormattedTextView({Key? key, required this.text}) : super(key: key);

  @override
  State<FormattedTextView> createState() => _FormattedTextViewState();
}

class _FormattedTextViewState extends State<FormattedTextView> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FormattedTextVM>(
        converter: (store) => FormattedTextVM(
            store.state.untitled.transcriptTextList,
            store.state.untitled.transcriptText,
            store.state.untitled.highlightSpan,
            store.state.untitled.highlightedSpanIndex,
            store.state.untitled.recordedLength),
        builder: (_, viewModel) {
          List<InlineSpan> allSpans =
              TextFormatter.formatTextList(viewModel.transcriptTextList)
                  .asMap()
                  .map((index, pair) {
                    final List<String> words = pair.first.split(' ');

                    Iterable<InlineSpan> sentenceSpans = words.map((word) {
                      void onTapSpan() {
                        print("Text: $pair tapped");
                        final seekTimeInMS =
                            min(viewModel.audioDuration, pair.second) * 1000;
                        print('seeking: ${seekTimeInMS / 1000}s');
                        JustAudioPlayerWidgetState.player
                            .seek(Duration(milliseconds: seekTimeInMS.toInt()));
                      }

                      TextStyle shouldHighlightSpan() {
                        if (viewModel.highlightedSpanIndex == index) {
                          return TextStyle(color: Colors.black);
                        }
                        return TextStyle(color: Colors.black38);
                      }

                      return WidgetSpan(
                          child: AnimatedDefaultTextStyle(
                        child: GestureDetector(
                          child: Text('$word '),
                          onTap: onTapSpan,
                        ),
                        style: GoogleFonts.rubik(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                height: 1.4)
                            .merge(shouldHighlightSpan()),
                        duration: Duration(milliseconds: 300),
                      ));
                    });
                    return MapEntry(index, sentenceSpans);
                  })
                  .values
                  .expand((element) => element) // flattens nested list
                  .toList();

          return Container(
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: RangeMaintainingScrollPhysics(),
                child: RichText(text: TextSpan(children: allSpans))),
          );
        });
  }
}

class FormattedTextVM {
  List<Pair<String, double>> transcriptTextList;
  String text;
  void Function(int) highlightSpan;
  int? highlightedSpanIndex;
  double audioDuration;
  FormattedTextVM(this.transcriptTextList, this.text, this.highlightSpan,
      this.highlightedSpanIndex, this.audioDuration);
  @override
  bool operator ==(other) {
    return (other is FormattedTextVM) &&
        (transcriptTextList == other.transcriptTextList) &&
        (text == other.text) &&
        (highlightSpan == other.highlightSpan) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(transcriptTextList, text, highlightSpan,
        highlightedSpanIndex, audioDuration);
  }
}
