import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Minutes/utils/extensions.dart';

import '../redux_/rootStore.dart';
import '../utils/pair.dart';
import 'just_audio_player.dart';

class FormattedTextView extends StatefulWidget {
  const FormattedTextView({Key? key}) : super(key: key);

  @override
  State<FormattedTextView> createState() => _FormattedTextViewState();
}

class _FormattedTextViewState extends State<FormattedTextView> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FormattedTextVM>(
        distinct: true,
        converter: (store) => FormattedTextVM(
            store.state.transcript.transcriptTextList,
            store.state.transcript.transcriptText,
            store.state.transcript.highlightSpan,
            store.state.transcript.highlightedSpanIndex,
            store.state.audio.duration),
        builder: (_, viewModel) {
          List<InlineSpan> allSpans =
              TextFormatter.formatTextList(viewModel.transcriptTextList)
                  .asMap()
                  .map((index, pair) {
                    final List<String> words = pair.first.split(' ');

                    List<InlineSpan> sentenceSpans = List.empty(growable: true);

                    void onTapSpan() {
                      print("Text: $pair tapped");
                      final Duration seekTime = DurationUtils.min(
                          viewModel.audioDuration, pair.second);
                      print('seeking: ${seekTime.inSeconds}s');
                      JustAudioPlayerWidgetState.player.seek(seekTime);
                    }

                    TextStyle shouldHighlightSpan() {
                      if (viewModel.highlightedSpanIndex == index) {
                        return TextStyle(color: Colors.black);
                      }
                      return TextStyle(color: Colors.black38);
                    }

                    Widget defaultSpan(String text) {
                      return AnimatedDefaultTextStyle(
                        child: GestureDetector(
                          child: Text('$text '),
                          onTap: onTapSpan,
                        ),
                        style: GoogleFonts.rubik(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                height: 1.4)
                            .merge(shouldHighlightSpan()),
                        duration: Duration(milliseconds: 300),
                      );
                    }

                    for (final word in words) {
                      if (word.contains('\n')) {
                        Iterable<InlineSpan> spans =
                            word.split('\n').map((text) {
                          return WidgetSpan(
                              child: text.isEmpty
                                  ? SizedBox(height: 10, width: double.infinity)
                                  : defaultSpan(text));
                        });
                        sentenceSpans.addAll(spans);
                      } else {
                        sentenceSpans.add(WidgetSpan(child: defaultSpan(word)));
                      }
                    }

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
  List<Pair<String, Duration>> transcriptTextList;
  String text;
  void Function(int) highlightSpan;
  int? highlightedSpanIndex;
  Duration audioDuration;
  FormattedTextVM(this.transcriptTextList, this.text, this.highlightSpan,
      this.highlightedSpanIndex, this.audioDuration);
  @override
  bool operator ==(other) {
    return (other is FormattedTextVM) &&
        (transcriptTextList == other.transcriptTextList) &&
        (text == other.text) &&
        (highlightSpan == other.highlightSpan) &&
        (highlightedSpanIndex == other.highlightedSpanIndex) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(transcriptTextList, text, highlightSpan,
        highlightedSpanIndex, audioDuration);
  }
}
