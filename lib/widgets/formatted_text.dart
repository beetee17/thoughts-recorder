import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/utils/extensions.dart';

import '../redux_/rootStore.dart';
import '../utils/transcript_pair.dart';
import 'default_span.dart';

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
        converter: (store) =>
            FormattedTextVM(store.state.transcript.transcriptTextList),
        builder: (_, viewModel) {
          List<InlineSpan> allSpans = viewModel.transcriptTextList
              .asMap()
              .map((wordIndex, pair) {
                final String word = pair.word;

                List<InlineSpan> wordSpans = List.empty(growable: true);

                if (word.contains('\n')) {
                  Iterable<InlineSpan> spans = word.split('\n').map((text) {
                    return WidgetSpan(
                        child: text.isEmpty
                            ? SizedBox(
                                height: 10,
                                width: double.infinity) // To display a new line
                            : DefaultSpan(
                                pair: pair,
                                wordIndex: wordIndex,
                              ));
                  });
                  wordSpans.addAll(spans);
                } else {
                  wordSpans.add(WidgetSpan(
                      child: DefaultSpan(
                    pair: pair,
                    wordIndex: wordIndex,
                  )));
                }

                return MapEntry(wordIndex, wordSpans);
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
  List<TranscriptPair> transcriptTextList;
  FormattedTextVM(this.transcriptTextList);
  @override
  bool operator ==(other) {
    return (other is FormattedTextVM) &&
        (transcriptTextList == other.transcriptTextList);
  }

  @override
  int get hashCode {
    return transcriptTextList.hashCode;
  }
}
